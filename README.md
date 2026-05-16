<p align="center">
  <img src="https://raw.githubusercontent.com/faisalaffan/claudio/dev/assets/03_BANNER_DARK.png" alt="Claudio Banner" width="100%">
</p>

<p align="center">
  🇬🇧 English · 🇮🇩 <a href="README.id.md">Bahasa Indonesia</a>
</p>

# claudio

Multi-provider AI SDK for Dart/Flutter — one interface, many providers.

[![pub package](https://img.shields.io/pub/v/claudio_sdk.svg)](https://pub.dev/packages/claudio_sdk)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Install

### Dart / Flutter

```yaml
dependencies:
  claudio_sdk: ^0.1.0
```

### Docker

```bash
docker pull ghcr.io/faisalaffan/claudio:latest
```

```dockerfile
FROM ghcr.io/faisalaffan/claudio:latest

COPY . .
RUN dart run main.dart
```

## Quick Start

```dart
import 'package:claudio_sdk/claudio_sdk.dart';

void main() async {
  final client = ClaudioClient(
    apiKey: 'sk-ant-your-key',
    provider: Provider.anthropic,
  );

  final msg = await client.messages.create(
    CreateMessageRequest(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1024,
      messages: [
        MessageParam(role: 'user', content: 'Hello!'),
      ],
    ),
  );

  print(msg.text);
  client.close();
}
```

## Providers

```dart
// Anthropic
ClaudioClient(apiKey: 'sk-ant-...', provider: Provider.anthropic);

// DeepSeek (Anthropic-compatible API)
ClaudioClient(apiKey: 'sk-ds-...', provider: Provider.deepseek);

// Auto-detect from environment
ClaudioClient.fromEnvironment();
```

## Features

- **Messages API** — `create()` and `createStream()` with SSE
- **Multi-tools** — schema builder for type-safe JSON Schema
- **Extended thinking** — enabled, disabled, adaptive
- **Streaming** — real-time token & tool input chunks
- **Error handling** — typed exception hierarchy (auth, rate limit, network, etc.)
- **Retry** — exponential backoff + jitter for 429 and 5xx

## Tools & Streaming

```dart
final tool = Tool(
  name: 'get_weather',
  description: 'Weather by city.',
  inputSchema: SchemaBuilder().object(
    properties: {
      'city': SchemaProperty.string(description: 'City name'),
    },
    required: ['city'],
  ).build(),
);

final stream = client.messages.createStream(
  CreateMessageRequest(
    model: 'claude-sonnet-4-20250514',
    maxTokens: 1024,
    messages: [MessageParam(role: 'user', content: 'Weather in Jakarta?')],
    tools: [tool],
  ),
);

await for (final event in stream) {
  if (event is ContentBlockDeltaEvent) {
    switch (event.delta) {
      case TextDelta(:final text): stdout.write(text);
      case InputJsonDelta(:final partialJson): print(partialJson);
    }
  }
}
```

## Error Handling

```dart
try {
  final msg = await client.messages.create(request);
} on AuthenticationException catch (e) {
  print('Auth error: ${e.message}');
} on RateLimitException catch (e) {
  print('Rate limited, retry after ${e.retryAfter}');
} on ApiException catch (e) {
  print('Server error ${e.statusCode}: ${e.message}');
} on NetworkException catch (e) {
  print('Network: ${e.message}');
}
```

## Sponsor

If you find this project useful, consider supporting its development:

[![GitHub Sponsors](https://img.shields.io/badge/GitHub%20Sponsors-faisalaffan-ea4aaa?logo=github)](https://github.com/sponsors/faisalaffan)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-faisalaffan-ff5e5b?logo=kofi)](https://ko-fi.com/faisalaffan)
[![Saweria](https://img.shields.io/badge/Saweria-faisalaffan-fdba74?logo=buymeacoffee)](https://saweria.co/faisalaffan)

## License

MIT

---

<p align="center">
  <img src="https://raw.githubusercontent.com/faisalaffan/claudio/dev/assets/04_LOGO_SINGLE.png" alt="Claudio" width="120">
</p>
