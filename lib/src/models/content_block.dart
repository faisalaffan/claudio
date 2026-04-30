import 'package:meta/meta.dart';

/// Base sealed class for all content block types in the Anthropic Messages API.
///
/// Content blocks represent different types of content within a message,
/// such as text, images, documents, tool use/results, and thinking blocks.
///
/// Each subclass corresponds to a specific `type` value in the API JSON:
/// - `"text"` → [TextBlock]
/// - `"image"` → [ImageBlock]
/// - `"document"` → [DocumentBlock]
/// - `"tool_use"` → [ToolUseBlock]
/// - `"tool_result"` → [ToolResultBlock]
/// - `"thinking"` → [ThinkingBlock]
/// - `"redacted_thinking"` → [RedactedThinkingBlock]
@immutable
sealed class ContentBlock {
  /// The type identifier for JSON serialization.
  String get type;

  const ContentBlock();

  /// Converts this [ContentBlock] to a JSON map.
  Map<String, dynamic> toJson();
}

// ---------------------------------------------------------------------------
// TextBlock
// ---------------------------------------------------------------------------

/// A content block containing plain text.
///
/// Example JSON:
/// ```json
/// {"type": "text", "text": "Hello, world!"}
/// ```
@immutable
class TextBlock extends ContentBlock {
  /// The text content.
  final String text;

  @override
  String get type => 'text';

  /// Creates a [TextBlock] with the given [text].
  const TextBlock({required this.text});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextBlock && other.text == text;
  }

  @override
  int get hashCode => Object.hash(type, text);

  @override
  String toString() => 'TextBlock(text: $text)';
}

// ---------------------------------------------------------------------------
// ImageSource
// ---------------------------------------------------------------------------

/// Describes the source of an image: either base64-encoded data or a URL.
///
/// Example JSON (base64):
/// ```json
/// {"type": "base64", "media_type": "image/png", "data": "iVBOR..."}
/// ```
///
/// Example JSON (url):
/// ```json
/// {"type": "url", "media_type": "image/png", "data": "https://..."}
/// ```
@immutable
class ImageSource {
  /// The source type: `"base64"` or `"url"`.
  final String type;

  /// The MIME type of the image (e.g. `"image/png"`, `"image/jpeg"`).
  final String mediaType;

  /// The base64-encoded image data, or the image URL.
  final String data;

  /// Creates an [ImageSource] with the given [type], [mediaType], and [data].
  const ImageSource({
    required this.type,
    required this.mediaType,
    required this.data,
  });

  /// Creates an [ImageSource] from a JSON map.
  factory ImageSource.fromJson(Map<String, dynamic> json) {
    return ImageSource(
      type: json['type'] as String,
      mediaType: json['media_type'] as String,
      data: json['data'] as String,
    );
  }

  /// Converts this [ImageSource] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'media_type': mediaType,
      'data': data,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageSource &&
        other.type == type &&
        other.mediaType == mediaType &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(type, mediaType, data);

  @override
  String toString() =>
      'ImageSource(type: $type, mediaType: $mediaType, data: $data)';
}

// ---------------------------------------------------------------------------
// ImageBlock
// ---------------------------------------------------------------------------

/// A content block containing an image.
///
/// Example JSON:
/// ```json
/// {
///   "type": "image",
///   "source": {"type": "base64", "media_type": "image/png", "data": "iVBOR..."}
/// }
/// ```
@immutable
class ImageBlock extends ContentBlock {
  /// The image source (base64 data or URL).
  final ImageSource source;

  @override
  String get type => 'image';

  /// Creates an [ImageBlock] with the given [source].
  const ImageBlock({required this.source});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'source': source.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageBlock && other.source == source;
  }

  @override
  int get hashCode => Object.hash(type, source);

  @override
  String toString() => 'ImageBlock(source: $source)';
}

// ---------------------------------------------------------------------------
// DocumentSource
// ---------------------------------------------------------------------------

/// Describes the source of a document: either base64-encoded data or a URL.
///
/// Example JSON (base64):
/// ```json
/// {"type": "base64", "media_type": "application/pdf", "data": "JVBERi0..."}
/// ```
@immutable
class DocumentSource {
  /// The source type: `"base64"` or `"url"`.
  final String type;

  /// The MIME type of the document (e.g. `"application/pdf"`).
  final String mediaType;

  /// The base64-encoded document data, or the document URL.
  final String data;

  /// Creates a [DocumentSource] with the given [type], [mediaType], and [data].
  const DocumentSource({
    required this.type,
    required this.mediaType,
    required this.data,
  });

  /// Creates a [DocumentSource] from a JSON map.
  factory DocumentSource.fromJson(Map<String, dynamic> json) {
    return DocumentSource(
      type: json['type'] as String,
      mediaType: json['media_type'] as String,
      data: json['data'] as String,
    );
  }

  /// Converts this [DocumentSource] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'media_type': mediaType,
      'data': data,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentSource &&
        other.type == type &&
        other.mediaType == mediaType &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(type, mediaType, data);

  @override
  String toString() =>
      'DocumentSource(type: $type, mediaType: $mediaType, data: $data)';
}

// ---------------------------------------------------------------------------
// DocumentBlock
// ---------------------------------------------------------------------------

/// A content block containing a document.
///
/// Example JSON:
/// ```json
/// {
///   "type": "document",
///   "source": {"type": "base64", "media_type": "application/pdf", "data": "JVBERi0..."}
/// }
/// ```
@immutable
class DocumentBlock extends ContentBlock {
  /// The document source (base64 data or URL).
  final DocumentSource source;

  @override
  String get type => 'document';

  /// Creates a [DocumentBlock] with the given [source].
  const DocumentBlock({required this.source});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'source': source.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentBlock && other.source == source;
  }

  @override
  int get hashCode => Object.hash(type, source);

  @override
  String toString() => 'DocumentBlock(source: $source)';
}

// ---------------------------------------------------------------------------
// ToolUseBlock
// ---------------------------------------------------------------------------

/// A content block indicating the model wants to call a tool.
///
/// Example JSON:
/// ```json
/// {
///   "type": "tool_use",
///   "id": "toolu_01A09q90qw90lq917835lq9",
///   "name": "get_weather",
///   "input": {"location": "San Francisco, CA"}
/// }
/// ```
@immutable
class ToolUseBlock extends ContentBlock {
  /// The unique identifier for this tool use invocation.
  final String id;

  /// The name of the tool being called.
  final String name;

  /// The input parameters for the tool, matching the tool's input schema.
  final Map<String, dynamic> input;

  @override
  String get type => 'tool_use';

  /// Creates a [ToolUseBlock] with the given [id], [name], and [input].
  const ToolUseBlock({
    required this.id,
    required this.name,
    required this.input,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'input': input,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ToolUseBlock) return false;
    if (other.id != id || other.name != name) return false;
    return _mapEquals(other.input, input);
  }

  @override
  int get hashCode => Object.hash(type, id, name, Object.hashAll(input.keys));

  @override
  String toString() => 'ToolUseBlock(id: $id, name: $name, input: $input)';
}

// ---------------------------------------------------------------------------
// ToolResultBlock
// ---------------------------------------------------------------------------

/// A content block containing the result of a tool execution.
///
/// Sent by the developer in a `user` message to provide tool results
/// back to the model after a [ToolUseBlock] response.
///
/// Example JSON:
/// ```json
/// {
///   "type": "tool_result",
///   "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
///   "content": [{"type": "text", "text": "15 degrees"}]
/// }
/// ```
@immutable
class ToolResultBlock extends ContentBlock {
  /// The ID of the [ToolUseBlock] this result corresponds to.
  final String toolUseId;

  /// The content of the tool result (text, images, or other content blocks).
  final List<ContentBlock> content;

  /// Whether the tool execution resulted in an error.
  /// Only included in JSON when `true`.
  final bool isError;

  @override
  String get type => 'tool_result';

  /// Creates a [ToolResultBlock] with the given [toolUseId], [content],
  /// and optional [isError] flag (defaults to `false`).
  const ToolResultBlock({
    required this.toolUseId,
    this.content = const [],
    this.isError = false,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
      'tool_use_id': toolUseId,
      'content': content.map((block) => block.toJson()).toList(),
    };
    if (isError) {
      json['is_error'] = true;
    }
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ToolResultBlock) return false;
    if (other.toolUseId != toolUseId || other.isError != isError) return false;
    if (other.content.length != content.length) return false;
    for (var i = 0; i < content.length; i++) {
      if (other.content[i] != content[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(type, toolUseId, isError, Object.hashAll(content));

  @override
  String toString() =>
      'ToolResultBlock(toolUseId: $toolUseId, content: $content, isError: $isError)';
}

// ---------------------------------------------------------------------------
// ThinkingBlock
// ---------------------------------------------------------------------------

/// A content block containing the model's extended thinking process.
///
/// Only present when extended thinking is enabled in the request.
///
/// Example JSON:
/// ```json
/// {
///   "type": "thinking",
///   "thinking": "Let me think about this step by step...",
///   "signature": "abc123..."
/// }
/// ```
@immutable
class ThinkingBlock extends ContentBlock {
  /// The model's thinking text.
  final String thinking;

  /// A signature for verification of the thinking content.
  final String signature;

  @override
  String get type => 'thinking';

  /// Creates a [ThinkingBlock] with the given [thinking] text and [signature].
  const ThinkingBlock({
    required this.thinking,
    required this.signature,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'thinking': thinking,
      'signature': signature,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingBlock &&
        other.thinking == thinking &&
        other.signature == signature;
  }

  @override
  int get hashCode => Object.hash(type, thinking, signature);

  @override
  String toString() =>
      'ThinkingBlock(thinking: $thinking, signature: $signature)';
}

// ---------------------------------------------------------------------------
// RedactedThinkingBlock
// ---------------------------------------------------------------------------

/// A content block representing redacted thinking content.
///
/// The API may redact certain thinking content for safety reasons.
/// The [data] field contains an opaque string representing the redacted content.
///
/// Example JSON:
/// ```json
/// {"type": "redacted_thinking", "data": "opaque-redacted-data..."}
/// ```
@immutable
class RedactedThinkingBlock extends ContentBlock {
  /// Opaque data representing the redacted thinking content.
  final String data;

  @override
  String get type => 'redacted_thinking';

  /// Creates a [RedactedThinkingBlock] with the given [data].
  const RedactedThinkingBlock({required this.data});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedactedThinkingBlock && other.data == data;
  }

  @override
  int get hashCode => Object.hash(type, data);

  @override
  String toString() => 'RedactedThinkingBlock(data: $data)';
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Deep equality check for two maps (used by [ToolUseBlock]).
bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final va = a[key];
    final vb = b[key];
    if (va is Map<String, dynamic> && vb is Map<String, dynamic>) {
      if (!_mapEquals(va, vb)) return false;
    } else if (va is List && vb is List) {
      if (!_listEquals(va, vb)) return false;
    } else if (va != vb) {
      return false;
    }
  }
  return true;
}

/// Deep equality check for two lists (used by [_mapEquals]).
bool _listEquals(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final va = a[i];
    final vb = b[i];
    if (va is Map<String, dynamic> && vb is Map<String, dynamic>) {
      if (!_mapEquals(va, vb)) return false;
    } else if (va is List && vb is List) {
      if (!_listEquals(va, vb)) return false;
    } else if (va != vb) {
      return false;
    }
  }
  return true;
}
