import '../models/content_block.dart';

/// Handles polymorphic deserialization of [ContentBlock] subclasses from JSON.
///
/// The parser reads the `type` field from a JSON map and dispatches to the
/// appropriate [ContentBlock] subclass constructor. All 7 content block types
/// defined by the Anthropic Messages API are supported:
///
/// | `type` value          | Dart class              |
/// |-----------------------|-------------------------|
/// | `text`                | [TextBlock]             |
/// | `image`               | [ImageBlock]            |
/// | `document`            | [DocumentBlock]         |
/// | `tool_use`            | [ToolUseBlock]          |
/// | `tool_result`         | [ToolResultBlock]       |
/// | `thinking`            | [ThinkingBlock]         |
/// | `redacted_thinking`   | [RedactedThinkingBlock] |
///
/// Unknown types are handled gracefully by returning a [TextBlock] with a
/// placeholder message, ensuring forward compatibility when the API
/// introduces new content block types.
///
/// Example:
/// ```dart
/// final json = {'type': 'text', 'text': 'Hello!'};
/// final block = ContentBlockParser.parse(json);
/// // block is TextBlock(text: 'Hello!')
/// ```
class ContentBlockParser {
  /// Prevent instantiation — all methods are static.
  const ContentBlockParser._();

  /// Parses a JSON map into the appropriate [ContentBlock] subclass.
  ///
  /// The [json] map must contain a `type` field (a [String]) that
  /// identifies which content block subclass to create.
  ///
  /// Nested content blocks (e.g. inside [ToolResultBlock.content]) are
  /// parsed recursively.
  ///
  /// Returns a [TextBlock] with a placeholder message for unrecognised
  /// `type` values, providing forward compatibility.
  static ContentBlock parse(Map<String, dynamic> json) {
    final type = json['type'] as String;

    return switch (type) {
      'text' => _parseTextBlock(json),
      'image' => _parseImageBlock(json),
      'document' => _parseDocumentBlock(json),
      'tool_use' => _parseToolUseBlock(json),
      'tool_result' => _parseToolResultBlock(json),
      'thinking' => _parseThinkingBlock(json),
      'redacted_thinking' => _parseRedactedThinkingBlock(json),
      _ => TextBlock(text: '[unknown block type: $type]'),
    };
  }

  /// Parses a list of JSON maps into a list of [ContentBlock]s.
  ///
  /// Convenience method for parsing arrays of content blocks, such as
  /// the `content` field in a [ToolResultBlock] or a [Message].
  static List<ContentBlock> parseList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => parse(item as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Private parsers for each content block type
  // -------------------------------------------------------------------------

  static TextBlock _parseTextBlock(Map<String, dynamic> json) {
    return TextBlock(text: json['text'] as String);
  }

  static ImageBlock _parseImageBlock(Map<String, dynamic> json) {
    return ImageBlock(
      source: ImageSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  static DocumentBlock _parseDocumentBlock(Map<String, dynamic> json) {
    return DocumentBlock(
      source:
          DocumentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  static ToolUseBlock _parseToolUseBlock(Map<String, dynamic> json) {
    return ToolUseBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      input: Map<String, dynamic>.from(json['input'] as Map),
    );
  }

  static ToolResultBlock _parseToolResultBlock(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final List<ContentBlock> content;

    if (rawContent is List) {
      // Recursively parse nested content blocks.
      content = parseList(rawContent);
    } else {
      content = const [];
    }

    return ToolResultBlock(
      toolUseId: json['tool_use_id'] as String,
      content: content,
      isError: json['is_error'] as bool? ?? false,
    );
  }

  static ThinkingBlock _parseThinkingBlock(Map<String, dynamic> json) {
    return ThinkingBlock(
      thinking: json['thinking'] as String,
      signature: json['signature'] as String,
    );
  }

  static RedactedThinkingBlock _parseRedactedThinkingBlock(
    Map<String, dynamic> json,
  ) {
    return RedactedThinkingBlock(data: json['data'] as String);
  }
}
