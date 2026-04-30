import '../models/content_block.dart';
import '../models/message.dart';
import '../models/request.dart';
import '../models/tool.dart';

/// A centralized entry point for serializing SDK model objects to JSON
/// maps matching the Anthropic API format.
///
/// The [Serializer] delegates to each model's `toJson()` method, which
/// already handles:
/// - **snake_case conversion** for field names (Dart camelCase → API
///   snake_case, e.g. `maxTokens` → `max_tokens`)
/// - **Optional field omission** (null fields are not included in the
///   output map)
///
/// This class acts as a facade so that transport and client layers have
/// a single, consistent place to perform serialization without coupling
/// directly to individual model classes.
///
/// Example:
/// ```dart
/// final serializer = Serializer();
/// final json = serializer.serializeRequest(request);
/// // json is ready to be encoded and sent to the API
/// ```
class Serializer {
  /// Creates a [Serializer] instance.
  const Serializer();

  /// Serializes a [CreateMessageRequest] to a JSON map matching the
  /// Anthropic API `POST /v1/messages` request body format.
  ///
  /// Delegates to [CreateMessageRequest.toJson], which converts field
  /// names to snake_case and omits null optional fields.
  ///
  /// Example output:
  /// ```json
  /// {
  ///   "model": "claude-sonnet-4-20250514",
  ///   "max_tokens": 1024,
  ///   "messages": [{"role": "user", "content": "Hello!"}],
  ///   "stream": false
  /// }
  /// ```
  Map<String, dynamic> serializeRequest(CreateMessageRequest request) {
    return request.toJson();
  }

  /// Serializes a [MessageParam] to a JSON map.
  ///
  /// Delegates to [MessageParam.toJson], which handles both string
  /// content and list-of-[ContentBlock] content.
  Map<String, dynamic> serializeMessage(MessageParam message) {
    return message.toJson();
  }

  /// Serializes a [Tool] definition to a JSON map.
  ///
  /// Delegates to [Tool.toJson], which converts `inputSchema` to
  /// `input_schema` (snake_case).
  Map<String, dynamic> serializeTool(Tool tool) {
    return tool.toJson();
  }

  /// Serializes a [ContentBlock] to a JSON map.
  ///
  /// Delegates to [ContentBlock.toJson], which includes the `type`
  /// discriminator field and converts all field names to snake_case
  /// (e.g. `toolUseId` → `tool_use_id`, `mediaType` → `media_type`).
  Map<String, dynamic> serializeContentBlock(ContentBlock block) {
    return block.toJson();
  }
}
