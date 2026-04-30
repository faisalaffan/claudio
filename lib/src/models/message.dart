import 'package:meta/meta.dart';

import 'content_block.dart';
import 'usage.dart';

// ---------------------------------------------------------------------------
// StopReason
// ---------------------------------------------------------------------------

/// The reason the model stopped generating content.
///
/// Maps to the `stop_reason` field in the API response JSON using
/// snake_case values: `end_turn`, `max_tokens`, `stop_sequence`, `tool_use`.
enum StopReason {
  /// The model reached a natural stopping point.
  endTurn,

  /// The model hit the `max_tokens` limit.
  maxTokens,

  /// The model encountered one of the configured stop sequences.
  stopSequence,

  /// The model decided to use a tool.
  toolUse;

  /// Creates a [StopReason] from the snake_case API string value.
  ///
  /// Throws [ArgumentError] if [value] is not a recognised stop reason.
  ///
  /// Example:
  /// ```dart
  /// StopReason.fromString('end_turn') == StopReason.endTurn
  /// ```
  static StopReason fromString(String value) {
    return switch (value) {
      'end_turn' => StopReason.endTurn,
      'max_tokens' => StopReason.maxTokens,
      'stop_sequence' => StopReason.stopSequence,
      'tool_use' => StopReason.toolUse,
      _ => throw ArgumentError('Unknown stop reason: $value'),
    };
  }

  /// Converts this [StopReason] to the snake_case API string value.
  String toJson() {
    return switch (this) {
      StopReason.endTurn => 'end_turn',
      StopReason.maxTokens => 'max_tokens',
      StopReason.stopSequence => 'stop_sequence',
      StopReason.toolUse => 'tool_use',
    };
  }
}

// ---------------------------------------------------------------------------
// Message
// ---------------------------------------------------------------------------

/// A response message from the Anthropic Messages API.
///
/// Contains the model's response content along with metadata such as
/// the message [id], [model] used, [stopReason], and token [usage].
///
/// Example JSON:
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
@immutable
class Message {
  /// The unique identifier for this message.
  final String id;

  /// The role of the message author (typically `"assistant"`).
  final String role;

  /// The content blocks in this message.
  final List<ContentBlock> content;

  /// The model that generated this message.
  final String model;

  /// The reason the model stopped generating.
  final StopReason stopReason;

  /// Token usage information for this request/response.
  final Usage usage;

  /// Creates a [Message] with the given fields.
  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.model,
    required this.stopReason,
    required this.usage,
  });

  /// Convenience getter that joins the text from all [TextBlock]s
  /// in [content] with newlines.
  ///
  /// Non-text content blocks are ignored.
  String get text {
    return content
        .whereType<TextBlock>()
        .map((block) => block.text)
        .join('\n');
  }

  /// Extracts all [ToolUseBlock]s from [content].
  ///
  /// Returns an empty list if no tool use blocks are present.
  List<ToolUseBlock> get toolUseBlocks {
    return content.whereType<ToolUseBlock>().toList();
  }

  /// Converts this [Message] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'message',
      'role': role,
      'content': content.map((block) => block.toJson()).toList(),
      'model': model,
      'stop_reason': stopReason.toJson(),
      'usage': usage.toJson(),
    };
  }

  /// Creates a [Message] from a JSON map.
  ///
  /// NOTE: This is a basic implementation that parses [TextBlock] and
  /// [ToolUseBlock] content blocks. A full content block parser will
  /// be integrated later for complete polymorphic deserialization.
  factory Message.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>;
    final content = contentList.map((item) {
      final map = item as Map<String, dynamic>;
      return _parseContentBlock(map);
    }).toList();

    return Message(
      id: json['id'] as String,
      role: json['role'] as String,
      content: content,
      model: json['model'] as String,
      stopReason: StopReason.fromString(json['stop_reason'] as String),
      usage: Usage.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Message) return false;
    if (other.id != id ||
        other.role != role ||
        other.model != model ||
        other.stopReason != stopReason ||
        other.usage != usage) {
      return false;
    }
    if (other.content.length != content.length) return false;
    for (var i = 0; i < content.length; i++) {
      if (other.content[i] != content[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        role,
        Object.hashAll(content),
        model,
        stopReason,
        usage,
      );

  @override
  String toString() => 'Message(id: $id, role: $role, model: $model, '
      'stopReason: $stopReason, content: $content, usage: $usage)';
}

// ---------------------------------------------------------------------------
// MessageParam
// ---------------------------------------------------------------------------

/// A message parameter for API requests.
///
/// Represents a message in the conversation history sent to the API.
/// The [content] field can be either a plain [String] (shorthand for a
/// single text block) or a [List<ContentBlock>] for rich content.
///
/// Example JSON (string content):
/// ```json
/// {"role": "user", "content": "Hello!"}
/// ```
///
/// Example JSON (list content):
/// ```json
/// {"role": "user", "content": [{"type": "text", "text": "Hello!"}]}
/// ```
@immutable
class MessageParam {
  /// The role of the message author: `"user"` or `"assistant"`.
  final String role;

  /// The message content — either a [String] or a [List<ContentBlock>].
  final dynamic content;

  /// Creates a [MessageParam] with the given [role] and [content].
  ///
  /// [content] must be either a [String] or a [List<ContentBlock>].
  /// Throws [ArgumentError] if [content] is neither.
  MessageParam({
    required this.role,
    required this.content,
  }) {
    if (content is! String && content is! List<ContentBlock>) {
      throw ArgumentError(
        'content must be a String or List<ContentBlock>, '
        'got ${content.runtimeType}',
      );
    }
  }

  /// Converts this [MessageParam] to a JSON map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'role': role,
    };
    if (content is String) {
      json['content'] = content;
    } else if (content is List<ContentBlock>) {
      json['content'] =
          (content as List<ContentBlock>).map((b) => b.toJson()).toList();
    }
    return json;
  }

  /// Creates a [MessageParam] from a JSON map.
  factory MessageParam.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    dynamic content;
    if (rawContent is String) {
      content = rawContent;
    } else if (rawContent is List) {
      content = rawContent
          .map((item) => _parseContentBlock(item as Map<String, dynamic>))
          .toList();
    } else {
      content = rawContent;
    }
    return MessageParam(
      role: json['role'] as String,
      content: content,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MessageParam) return false;
    if (other.role != role) return false;
    if (content is String && other.content is String) {
      return content == other.content;
    }
    if (content is List<ContentBlock> && other.content is List<ContentBlock>) {
      final a = content as List<ContentBlock>;
      final b = other.content as List<ContentBlock>;
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    if (content is String) {
      return Object.hash(role, content);
    }
    if (content is List<ContentBlock>) {
      return Object.hash(role, Object.hashAll(content as List<ContentBlock>));
    }
    return Object.hash(role, content);
  }

  @override
  String toString() => 'MessageParam(role: $role, content: $content)';
}

// ---------------------------------------------------------------------------
// Basic content block parser (to be replaced by full parser later)
// ---------------------------------------------------------------------------

/// Parses a JSON map into a [ContentBlock].
///
/// This is a basic implementation that handles the most common block types.
/// It will be replaced by the full [ContentBlockParser] in the serialization
/// layer once that component is built.
ContentBlock _parseContentBlock(Map<String, dynamic> json) {
  final type = json['type'] as String;
  return switch (type) {
    'text' => TextBlock(text: json['text'] as String),
    'tool_use' => ToolUseBlock(
        id: json['id'] as String,
        name: json['name'] as String,
        input: Map<String, dynamic>.from(json['input'] as Map),
      ),
    'tool_result' => ToolResultBlock(
        toolUseId: json['tool_use_id'] as String,
        content: (json['content'] as List<dynamic>?)
                ?.map((item) =>
                    _parseContentBlock(item as Map<String, dynamic>))
                .toList() ??
            const [],
        isError: json['is_error'] as bool? ?? false,
      ),
    'thinking' => ThinkingBlock(
        thinking: json['thinking'] as String,
        signature: json['signature'] as String,
      ),
    'redacted_thinking' =>
      RedactedThinkingBlock(data: json['data'] as String),
    'image' => ImageBlock(
        source: ImageSource.fromJson(json['source'] as Map<String, dynamic>),
      ),
    'document' => DocumentBlock(
        source:
            DocumentSource.fromJson(json['source'] as Map<String, dynamic>),
      ),
    _ => TextBlock(text: '[unknown block type: $type]'),
  };
}
