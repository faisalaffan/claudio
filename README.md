# Anthropic SDK Dart

<!-- badges placeholder -->
[![pub package](https://img.shields.io/pub/v/anthropic_sdk_dart.svg)](https://pub.dev/packages/anthropic_sdk_dart)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A type-safe Dart/Flutter SDK for the [Anthropic Messages API](https://docs.anthropic.com/en/docs/about-claude/models) (Claude).

## Features

- Full **Messages API** support — create and stream responses
- **Multi-tools** with nested object type schemas (unlimited depth)
- Fluent **SchemaBuilder** API for type-safe JSON Schema construction
- **Streaming** via Server-Sent Events (SSE)
- **Extended thinking** support (enabled, disabled, adaptive)
- Structured **error handling** with typed exception hierarchy
- Automatic **retry** with exponential backoff and jitter
- Cross-platform: iOS, Android, macOS, Windows, Linux, Web, server-side Dart

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  anthropic_sdk_dart: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

void main() async {
  final client = AnthropicClient(apiKey: 'sk-ant-your-api-key');

  final message = await client.messages.create(
    CreateMessageRequest(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1024,
      messages: [
        MessageParam(role: 'user', content: 'Hello, Claude!'),
      ],
    ),
  );

  print(message.text);
  client.close();
}
```

## Usage Examples

### Client Initialization

```dart
// Explicit API key
final client = AnthropicClient(apiKey: 'sk-ant-your-api-key');

// From environment variable (reads ANTHROPIC_API_KEY)
final client = AnthropicClient.fromEnvironment();

// With custom configuration
final client = AnthropicClient(
  apiKey: 'sk-ant-your-api-key',
  baseUrl: 'https://api.anthropic.com',
  timeout: const Duration(seconds: 60),
  retryPolicy: const RetryPolicy(
    maxRetries: 3,
    initialDelay: Duration(seconds: 2),
  ),
);

// Always close when done
client.close();
```

### Simple Message

```dart
final message = await client.messages.create(
  CreateMessageRequest(
    model: 'claude-sonnet-4-20250514',
    maxTokens: 1024,
    systemPrompt: 'You are a helpful assistant.',
    messages: [
      MessageParam(role: 'user', content: 'What is Dart?'),
    ],
  ),
);

print(message.text);           // Response text
print(message.model);          // Model used
print(message.stopReason);     // end_turn, tool_use, etc.
print(message.usage.inputTokens);
print(message.usage.outputTokens);
```

### Single Tool with SchemaBuilder

```dart
// Define a tool with SchemaBuilder
final getWeatherTool = Tool(
  name: 'get_weather',
  description: 'Get current weather for a location.',
  inputSchema: SchemaBuilder().object(
    properties: {
      'location': SchemaProperty.string(
        description: 'City name, e.g. "Jakarta"',
      ),
      'unit': SchemaProperty.string(
        description: 'Temperature unit',
        enumValues: ['celsius', 'fahrenheit'],
      ),
    },
    required: ['location'],
  ).build(),
);

// Send request with tool
final response = await client.messages.create(
  CreateMessageRequest(
    model: 'claude-sonnet-4-20250514',
    maxTokens: 1024,
    messages: [
      MessageParam(role: 'user', content: 'What is the weather in Jakarta?'),
    ],
    tools: [getWeatherTool],
  ),
);

// Check if model wants to use a tool
if (response.hasToolUse) {
  for (final toolUse in response.toolUseBlocks) {
    print('Tool: ${toolUse.name}');
    print('Input: ${toolUse.input}');
  }
}
```

### Multi-Tools with Nested Object Type

```dart
// Tool with deeply nested object schema
final createOrderTool = Tool(
  name: 'create_order',
  description: 'Create a new order with customer and items.',
  inputSchema: SchemaBuilder().object(
    properties: {
      'customer': SchemaProperty.object(
        description: 'Customer data',
        properties: {
          'name': SchemaProperty.string(description: 'Customer name'),
          'email': SchemaProperty.string(description: 'Customer email'),
          'address': SchemaProperty.object(
            description: 'Shipping address',
            properties: {
              'street': SchemaProperty.string(description: 'Street'),
              'city': SchemaProperty.string(description: 'City'),
              'zip': SchemaProperty.string(description: 'Zip code'),
            },
            required: ['street', 'city'],
          ),
        },
        required: ['name', 'email'],
      ),
      'items': SchemaProperty.array(
        description: 'Order items',
        items: SchemaProperty.object(
          properties: {
            'product_id': SchemaProperty.string(),
            'quantity': SchemaProperty.integer(),
            'options': SchemaProperty.array(
              items: SchemaProperty.string(),
            ),
          },
          required: ['product_id', 'quantity'],
        ),
      ),
      'payment_method': SchemaProperty.string(
        enumValues: ['credit_card', 'bank_transfer', 'e_wallet'],
      ),
    },
    required: ['customer', 'items'],
  ).build(),
);

final checkInventoryTool = Tool(
  name: 'check_inventory',
  description: 'Check product stock availability.',
  inputSchema: SchemaBuilder().object(
    properties: {
      'product_id': SchemaProperty.string(description: 'Product ID'),
      'warehouse': SchemaProperty.string(
        enumValues: ['jakarta', 'surabaya', 'bandung'],
      ),
    },
    required: ['product_id'],
  ).build(),
);

// Send request with multiple tools
final response = await client.messages.create(
  CreateMessageRequest(
    model: 'claude-sonnet-4-20250514',
    maxTokens: 1024,
    messages: [
      MessageParam(
        role: 'user',
        content: 'Create an order for Budi (budi@email.com), '
            '2x SKU-001 and 1x SKU-002, pay with e-wallet.',
      ),
    ],
    tools: [createOrderTool, checkInventoryTool],
    toolChoice: const ToolChoice.auto(),
  ),
);
```

### Streaming Response

```dart
final stream = client.messages.createStream(
  CreateMessageRequest(
    model: 'claude-sonnet-4-20250514',
    maxTokens: 1024,
    messages: [
      MessageParam(role: 'user', content: 'Tell me a short story.'),
    ],
  ),
);

await for (final event in stream) {
  switch (event) {
    case MessageStartEvent(:final message):
      print('Stream started — ID: ${message.id}');

    case ContentBlockDeltaEvent(:final delta):
      switch (delta) {
        case TextDelta(:final text):
          stdout.write(text); // Print tokens as they arrive
        case InputJsonDelta(:final partialJson):
          stdout.write(partialJson); // Tool input chunks
        case ThinkingDelta(:final thinking):
          stdout.write(thinking); // Thinking content
      }

    case MessageDeltaEvent(:final delta, :final usage):
      print('\nStop reason: ${delta.stopReason}');
      print('Output tokens: ${usage.outputTokens}');

    case MessageStopEvent():
      print('Stream complete.');

    default:
      break;
  }
}
```

### Tool Use Conversation Flow

```dart
// 1. Send request with tools
final response = await client.messages.create(
  CreateMessageRequest(
    model: 'claude-sonnet-4-20250514',
    maxTokens: 1024,
    messages: [
      MessageParam(role: 'user', content: 'What is the weather in Tokyo?'),
    ],
    tools: [getWeatherTool],
  ),
);

// 2. Check for tool use and execute locally
if (response.hasToolUse) {
  final toolResults = <ToolResultBlock>[];

  for (final toolUse in response.toolUseBlocks) {
    // Execute tool locally (your implementation)
    final result = await executeMyTool(toolUse.name, toolUse.input);

    toolResults.add(createToolResult(
      toolUseId: toolUse.id,
      text: result,
    ));
  }

  // 3. Send tool results back to get final response
  final finalResponse = await client.messages.create(
    CreateMessageRequest(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1024,
      messages: [
        MessageParam(role: 'user', content: 'What is the weather in Tokyo?'),
        response.toAssistantParam(),
        createToolResultMessage(toolResults),
      ],
      tools: [getWeatherTool],
    ),
  );

  print(finalResponse.text);
}
```

## Error Handling

The SDK provides a structured exception hierarchy rooted at `AnthropicException`:

```
AnthropicException
├── AuthenticationException   — Invalid or missing API key (401)
├── RateLimitException        — Rate limit exceeded (429), includes retryAfter
├── InvalidRequestException   — Invalid request body (400)
├── ApiException              — Server errors (5xx)
├── NetworkException          — DNS, connection, or timeout failures
├── StreamException           — SSE streaming connection errors
└── ClientClosedException     — Client used after close()
```

```dart
try {
  final message = await client.messages.create(request);
  print(message.text);
} on AuthenticationException catch (e) {
  print('Auth error: ${e.message}');
} on RateLimitException catch (e) {
  print('Rate limited. Retry after: ${e.retryAfter}');
} on InvalidRequestException catch (e) {
  print('Bad request: ${e.message}');
} on ApiException catch (e) {
  print('Server error (${e.statusCode}): ${e.message}');
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
} on StreamException catch (e) {
  print('Stream error: ${e.message}');
}
```

All exceptions include `message`, `statusCode` (when applicable), and `requestId` (when available from the API response header).

## Configuration

### Retry Policy

The SDK automatically retries transient failures (429 and 5xx) with exponential backoff:

```dart
final client = AnthropicClient(
  apiKey: 'sk-ant-your-api-key',
  retryPolicy: const RetryPolicy(
    maxRetries: 3,          // Up to 4 total attempts (default: 2)
    initialDelay: Duration(seconds: 2), // Base delay (default: 1s)
  ),
);
```

- Retries: HTTP 429 (rate limit) and 5xx (server errors)
- No retry: HTTP 400 (bad request) and 401 (auth error)
- Backoff formula: `initialDelay × 2^attempt + jitter`
- Respects `retry-after` header on 429 responses

### Timeout

```dart
final client = AnthropicClient(
  apiKey: 'sk-ant-your-api-key',
  timeout: const Duration(seconds: 60), // Default: 120s
);
```

### Base URL

```dart
final client = AnthropicClient(
  apiKey: 'sk-ant-your-api-key',
  baseUrl: 'https://api.anthropic.com', // Default
);
```

## API Reference

### Core Classes

| Class | Description |
|-------|-------------|
| `AnthropicClient` | Main entry point. Manages HTTP connection, auth, and retry. |
| `MessagesApi` | Interface for `create()` and `createStream()` methods. |
| `CreateMessageRequest` | Request parameters: model, maxTokens, messages, tools, etc. |
| `Message` | API response with `text`, `toolUseBlocks`, `stopReason`, `usage`. |
| `MessageParam` | Input message with `role` and `content`. |

### Tool System

| Class | Description |
|-------|-------------|
| `Tool` | Tool definition with name, description, and inputSchema. |
| `ToolChoice` | Controls tool selection: `auto`, `any`, `tool(name)`, `none`. |
| `SchemaBuilder` | Fluent builder for JSON Schema (tool input schemas). |
| `SchemaProperty` | Type-safe schema properties: string, number, integer, boolean, array, object. |

### Content Blocks

| Class | Description |
|-------|-------------|
| `TextBlock` | Text content in messages. |
| `ToolUseBlock` | Tool call from the model (id, name, input). |
| `ToolResultBlock` | Tool execution result sent back to the model. |
| `ImageBlock` | Image content (base64 or URL source). |
| `ThinkingBlock` | Extended thinking content with signature. |

### Streaming

| Class | Description |
|-------|-------------|
| `MessageStreamEvent` | Base sealed class for all SSE events. |
| `MessageStartEvent` | Stream start with initial message metadata. |
| `ContentBlockDeltaEvent` | Incremental content: `TextDelta`, `InputJsonDelta`, `ThinkingDelta`. |
| `MessageDeltaEvent` | Final metadata: stop reason and usage. |
| `MessageStopEvent` | Stream complete. |

### Helper Functions

| Function | Description |
|----------|-------------|
| `createToolResult()` | Creates a `ToolResultBlock` from toolUseId and text/content. |
| `createToolResultMessage()` | Wraps tool results in a user `MessageParam`. |

## License

MIT — see [LICENSE](LICENSE) for details.
