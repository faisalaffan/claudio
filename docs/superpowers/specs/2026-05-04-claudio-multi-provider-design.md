# claudio — Multi-Provider AI SDK Design Spec

## Overview

`claudio` is a Dart/Flutter SDK that provides an Anthropic Messages API-compatible interface across multiple AI providers. Single client, switch provider via config. Rewrite from scratch, carrying over all features from the existing `anthropic_sdk_dart` v0.1.0.

**First release**: Anthropic + DeepSeek.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | Single client, provider via config (`Provider.anthropic` / `Provider.deepseek`) | Interface identik, consumer code unchanged |
| Model names | Free string (`model: 'deepseek-chat'`) | Fleksibel, tidak over-engineer |
| Unsupported features | Throw `UnsupportedFeatureException` before request | Strict validation, no silent data loss |
| Base URL | Auto from provider, cannot override | Simplicity; proxy support deferred |
| Start | Rewrite from zero | Clean structure, no legacy constraint |
| Features | All existing features carried over | Messages API, tools, SchemaBuilder, streaming, extended thinking, error handling, retry, cross-platform |

## Package Structure

```
claudio/
├── lib/
│   ├── claudio.dart                    # Single import entry point
│   ├── src/
│   │   ├── client/
│   │   │   ├── claudio_client.dart     # Main entry point
│   │   │   ├── provider.dart           # Provider enum
│   │   │   ├── client_config.dart      # Configuration
│   │   │   ├── retry_policy.dart       # Retry config + backoff logic
│   │   ├── providers/
│   │   │   ├── provider_adapter.dart   # Abstract interface
│   │   │   ├── anthropic_adapter.dart  # Anthropic API implementation
│   │   │   ├── deepseek_adapter.dart   # DeepSeek API implementation
│   │   ├── messages/
│   │   │   ├── messages_api.dart       # create() + createStream()
│   │   │   ├── create_request.dart     # CreateMessageRequest model
│   │   │   ├── message_response.dart   # Message response model
│   │   │   ├── content_block.dart      # TextBlock, ToolUseBlock, etc.
│   │   ├── streaming/
│   │   │   ├── stream_events.dart      # SSE event types (sealed class hierarchy)
│   │   │   ├── sse_decoder.dart        # SSE protocol parser
│   │   ├── tools/
│   │   │   ├── tool.dart               # Tool definition
│   │   │   ├── tool_choice.dart        # ToolChoice: auto, any, tool(name), none
│   │   │   ├── schema_builder.dart     # Fluent JSON Schema builder
│   │   │   ├── schema_property.dart    # Type-safe schema properties
│   │   ├── errors/
│   │   │   ├── claudio_exception.dart          # Base exception
│   │   │   ├── authentication_exception.dart   # 401
│   │   │   ├── rate_limit_exception.dart       # 429
│   │   │   ├── invalid_request_exception.dart  # 400
│   │   │   ├── api_exception.dart              # 5xx
│   │   │   ├── network_exception.dart          # DNS, connection, timeout
│   │   │   ├── stream_exception.dart           # SSE failures
│   │   │   ├── unsupported_feature_exception.dart  # Feature not supported by provider
│   │   │   ├── client_closed_exception.dart    # Use after close()
│   │   ├── http/
│   │   │   ├── http_client.dart        # HTTP layer with retry
├── test/                               # Mirrors lib/ structure
├── example/                            # Usage examples
├── pubspec.yaml
```

## Core Types

### ProviderAdapter (Abstract)

```dart
abstract class ProviderAdapter {
  Provider get provider;
  String get baseUrl;
  Set<Feature> get supportedFeatures;

  Map<String, String> buildHeaders(String apiKey);
  Uri buildUri(String path);
  void validateRequest(CreateMessageRequest request);
}
```

Each provider implements this interface. `validateRequest` checks the request against `supportedFeatures` and throws `UnsupportedFeatureException` if a requested feature is not available.

### Feature Flags

```dart
enum Feature {
  extendedThinking,
  imageInput,
  toolUse,
  streaming,
  systemPrompt,
  promptCaching,
}
```

### Provider Enum

```dart
enum Provider {
  anthropic,
  deepseek,
}
```

### Feature Matrix (v0.1.0)

| Feature | Anthropic | DeepSeek |
|---------|-----------|----------|
| Text generation | ✓ | ✓ |
| Streaming (SSE) | ✓ | ✓ |
| Tool use | ✓ | ✓ |
| System prompt | ✓ | ✓ |
| Image input | ✓ | ✗ |
| Extended thinking | ✓ | ✗ |
| Prompt caching | ✓ | ✗ |

DeepSeek feature support to be verified against their API docs and adjusted.

## Client API

### Initialization

```dart
// Explicit provider
final client = ClaudioClient(
  apiKey: 'sk-ant-...',
  provider: Provider.anthropic,
);

// From environment (reads API key + provider from env vars)
final client = ClaudioClient.fromEnvironment();

// Custom config
final client = ClaudioClient(
  apiKey: '...',
  provider: Provider.deepseek,
  timeout: const Duration(seconds: 60),
  retryPolicy: const RetryPolicy(maxRetries: 3),
);

// Cleanup
client.close();
```

### Messages API

Interface unchanged from Anthropic Messages API format:

```dart
final message = await client.messages.create(
  CreateMessageRequest(
    model: 'claude-sonnet-4-20250514',
    maxTokens: 1024,
    systemPrompt: 'You are a helpful assistant.',
    messages: [
      MessageParam(role: 'user', content: 'Hello!'),
    ],
  ),
);
```

Streaming:

```dart
final stream = client.messages.createStream(request);

await for (final event in stream) {
  switch (event) {
    case MessageStartEvent(:final message): // Stream started
    case ContentBlockDeltaEvent(:final delta): // TextDelta, InputJsonDelta, ThinkingDelta
    case MessageDeltaEvent(:final delta, :final usage): // Stop reason, usage
    case MessageStopEvent(): // Stream complete
  }
}
```

### Unsupported Feature Handling

```dart
try {
  final message = await client.messages.create(
    CreateMessageRequest(
      model: 'deepseek-chat',
      maxTokens: 1024,
      messages: [...],
      thinking: const ThinkingConfig.enabled(), // ❌ DeepSeek doesn't support this
    ),
  );
} on UnsupportedFeatureException catch (e) {
  print('${e.feature} not supported by ${e.provider}');
}
```

Throw happens at `validateRequest()` — before any HTTP call.

## Provider Differences

### Auth Headers

| Provider | Auth Header | Base URL |
|----------|------------|----------|
| Anthropic | `x-api-key: sk-ant-...` | `https://api.anthropic.com` |
| DeepSeek | `Authorization: Bearer sk-...` | `https://api.deepseek.com` |

Anthropic additionally requires `anthropic-version: 2023-06-01` header.

### Endpoints

Both use `POST /v1/messages` (DeepSeek is Anthropic-compatible).

## Request Flow

1. `ClaudioClient.messages.create(request)` dipanggil
2. Internal: pilih `ProviderAdapter` sesuai config
3. `adapter.validateRequest(request)` — cek feature compatibility
4. Build HTTP request: `adapter.buildHeaders()` + `adapter.buildUri()`
5. Send via HTTP client with retry policy
6. Normalize response to `Message` model

## Error Handling

### Exception Hierarchy

```
ClaudioException
├── AuthenticationException       — 401
├── RateLimitException            — 429, includes retryAfter
├── InvalidRequestException       — 400
├── ApiException                  — 5xx
├── NetworkException              — DNS, connection, timeout
├── StreamException               — SSE connection errors
├── UnsupportedFeatureException   — Thrown before request (NEW)
├── ClientClosedException         — Use after close()
```

### Retry Policy

- Retry: 429 and 5xx
- No retry: 400 and 401
- Backoff: `initialDelay × 2^attempt + random jitter`
- Respects `retry-after` header on 429
- Default: maxRetries=2, initialDelay=1s

## Tools & SchemaBuilder

Brought over unchanged from existing `anthropic_sdk_dart`:
- `Tool` — name, description, inputSchema
- `ToolChoice` — auto, any, tool(name), none
- `SchemaBuilder` — fluent JSON Schema construction
- `SchemaProperty` — string, number, integer, boolean, array, object
- Nested object schemas (unlimited depth)
- Tool use conversation flow (tool_use → tool_result → final response)

## Dependencies

**Runtime** (2 dependencies):
- `http` ^1.2.0 — HTTP client
- `meta` ^1.12.0 — Annotations (sealed classes)

**Dev**:
- `test` ^1.25.0 — Test runner
- `mockito` ^5.4.0 — HTTP mocking
- `kiri_check` ^1.3.1 — Property-based testing
- `lints` ^5.1.1 — Lint rules

## Testing Strategy

| Layer | Scope | Tool |
|-------|-------|------|
| Unit — Models | JSON serialization, validation | test + kiri_check |
| Unit — ProviderAdapter | Headers, URI construction, validation per provider | test |
| Unit — SchemaBuilder | JSON Schema generation, nested objects | test |
| Unit — RetryPolicy | Backoff math, jitter bounds | test |
| Unit — StreamDecoder | SSE parsing, chunk handling | test |
| Integration — HTTP | Mock server, simulated provider responses | test + mockito |
| E2E | Real API calls, gated by env var | test + API keys |

## Out of Scope (v0.1.0)

- Custom base URL override (auto only)
- Additional providers beyond Anthropic + DeepSeek
- Provider auto-detection from API key format
- Request/response middleware
- Rate limit pre-emptive queuing
