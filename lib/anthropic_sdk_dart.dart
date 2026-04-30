/// A type-safe Dart/Flutter SDK for the Anthropic Messages API (Claude).
///
/// This library provides a complete client for interacting with the
/// Anthropic Messages API, including support for multi-tools with
/// object type schemas, streaming via SSE, extended thinking, and
/// structured error handling with automatic retry.
///
/// ## Usage
///
/// ```dart
/// import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
///
/// final client = AnthropicClient(apiKey: 'your-api-key');
/// ```
library;

export 'src/client.dart';
export 'src/exceptions/exceptions.dart';
export 'src/messages_api.dart' show MessagesApi;
export 'src/models/content_block.dart';
export 'src/models/message.dart';
export 'src/models/request.dart';
export 'src/models/schema.dart';
export 'src/models/stream_event.dart';
export 'src/models/thinking.dart';
export 'src/models/tool.dart';
export 'src/models/usage.dart';
export 'src/tool_use_helpers.dart';
export 'src/transport/retry_handler.dart' show RetryPolicy;
