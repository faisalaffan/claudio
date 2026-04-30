import '../models/content_block.dart';
import '../models/message.dart';
import '../models/tool.dart';
import '../models/usage.dart';
import 'content_block_parser.dart';

/// A centralized entry point for deserializing Anthropic API JSON
/// responses into type-safe Dart model objects.
///
/// The [Deserializer] handles:
/// - **snake_case → camelCase conversion** for field names (API snake_case
///   → Dart camelCase, e.g. `stop_reason` → `stopReason`)
/// - **Polymorphic content block parsing** via [ContentBlockParser]
/// - **Forward compatibility** — unknown fields in JSON are silently
///   ignored (Requirement 8.7)
/// - **Default values** for optional fields that are missing from the
///   JSON response (Requirement 8.8)
///
/// This class acts as a facade so that transport and client layers have
/// a single, consistent place to perform deserialization without coupling
/// directly to individual model classes.
///
/// Example:
/// ```dart
/// final deserializer = Deserializer();
/// final message = deserializer.deserializeMessage(jsonMap);
/// // message is a fully typed Message object
/// ```
class Deserializer {
  /// Creates a [Deserializer] instance.
  const Deserializer();

  /// Deserializes a full API response JSON map into a [Message] object.
  ///
  /// Handles snake_case → camelCase conversion for fields like
  /// `stop_reason` → `stopReason`. Uses [ContentBlockParser] for
  /// polymorphic content block deserialization.
  ///
  /// Unknown fields in [json] are silently ignored for forward
  /// compatibility. Missing optional fields use sensible defaults.
  ///
  /// Example input:
  /// ```json
  /// {
  ///   "id": "msg_01XFDUDYJgAACzvnptvVoYEL",
  ///   "type": "message",
  ///   "role": "assistant",
  ///   "content": [{"type": "text", "text": "Hello!"}],
  ///   "model": "claude-sonnet-4-20250514",
  ///   "stop_reason": "end_turn",
  ///   "usage": {"input_tokens": 25, "output_tokens": 15}
  /// }
  /// ```
  Message deserializeMessage(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>;
    final content = contentList
        .map((item) => ContentBlockParser.parse(item as Map<String, dynamic>))
        .toList();

    return Message(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'assistant',
      content: content,
      model: json['model'] as String,
      stopReason: StopReason.fromString(json['stop_reason'] as String),
      usage: deserializeUsage(json['usage'] as Map<String, dynamic>),
    );
  }

  /// Deserializes a JSON map into the appropriate [ContentBlock] subclass.
  ///
  /// Delegates to [ContentBlockParser.parse], which reads the `type`
  /// field and dispatches to the correct subclass constructor.
  ///
  /// Unknown `type` values produce a [TextBlock] with a placeholder
  /// message for forward compatibility.
  ContentBlock deserializeContentBlock(Map<String, dynamic> json) {
    return ContentBlockParser.parse(json);
  }

  /// Deserializes a JSON map into a [Usage] object.
  ///
  /// Handles snake_case field names (`input_tokens`, `output_tokens`).
  /// Missing fields default to `0` for forward compatibility.
  ///
  /// Example input:
  /// ```json
  /// {"input_tokens": 25, "output_tokens": 15}
  /// ```
  Usage deserializeUsage(Map<String, dynamic> json) {
    return Usage(
      inputTokens: json['input_tokens'] as int? ?? 0,
      outputTokens: json['output_tokens'] as int? ?? 0,
    );
  }

  /// Deserializes a JSON map into a [Tool] object.
  ///
  /// Handles the snake_case `input_schema` field, converting it to
  /// the Dart `inputSchema` property. Missing `description` defaults
  /// to an empty string.
  ///
  /// Example input:
  /// ```json
  /// {
  ///   "name": "get_weather",
  ///   "description": "Get the weather for a location",
  ///   "input_schema": {
  ///     "type": "object",
  ///     "properties": {
  ///       "location": {"type": "string"}
  ///     }
  ///   }
  /// }
  /// ```
  Tool deserializeTool(Map<String, dynamic> json) {
    return Tool(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      inputSchema:
          Map<String, dynamic>.from(json['input_schema'] as Map),
    );
  }
}
