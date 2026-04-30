import 'package:meta/meta.dart';

import 'content_block.dart';
import 'message.dart';
import 'usage.dart';

// ---------------------------------------------------------------------------
// Delta hierarchy
// ---------------------------------------------------------------------------

/// Base sealed class for streaming content deltas.
///
/// Represents incremental content updates received during streaming.
/// Each subclass corresponds to a specific `type` value in the delta JSON:
/// - `"text_delta"` → [TextDelta]
/// - `"input_json_delta"` → [InputJsonDelta]
/// - `"thinking_delta"` → [ThinkingDelta]
@immutable
sealed class Delta {
  /// The type identifier for JSON serialization.
  String get type;

  const Delta();

  /// Converts this [Delta] to a JSON map.
  Map<String, dynamic> toJson();

  /// Creates the appropriate [Delta] subclass from a JSON map.
  ///
  /// Dispatches based on the `type` field in the JSON.
  /// Throws [ArgumentError] if the type is not recognised.
  factory Delta.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'text_delta' => TextDelta.fromJson(json),
      'input_json_delta' => InputJsonDelta.fromJson(json),
      'thinking_delta' => ThinkingDelta.fromJson(json),
      _ => throw ArgumentError('Unknown delta type: $type'),
    };
  }
}

/// A delta containing incremental text content.
///
/// Example JSON:
/// ```json
/// {"type": "text_delta", "text": "Hello"}
/// ```
@immutable
class TextDelta extends Delta {
  /// The incremental text content.
  final String text;

  @override
  String get type => 'text_delta';

  /// Creates a [TextDelta] with the given [text].
  const TextDelta({required this.text});

  /// Creates a [TextDelta] from a JSON map.
  factory TextDelta.fromJson(Map<String, dynamic> json) {
    return TextDelta(text: json['text'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {'type': type, 'text': text};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextDelta && other.text == text;
  }

  @override
  int get hashCode => Object.hash(type, text);

  @override
  String toString() => 'TextDelta(text: $text)';
}

/// A delta containing incremental JSON for tool input.
///
/// During streaming of a [ToolUseBlock], the tool input is sent
/// incrementally as partial JSON strings.
///
/// Example JSON:
/// ```json
/// {"type": "input_json_delta", "partial_json": "{\"location\":"}
/// ```
@immutable
class InputJsonDelta extends Delta {
  /// The partial JSON string for the tool input.
  final String partialJson;

  @override
  String get type => 'input_json_delta';

  /// Creates an [InputJsonDelta] with the given [partialJson].
  const InputJsonDelta({required this.partialJson});

  /// Creates an [InputJsonDelta] from a JSON map.
  factory InputJsonDelta.fromJson(Map<String, dynamic> json) {
    return InputJsonDelta(partialJson: json['partial_json'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {'type': type, 'partial_json': partialJson};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InputJsonDelta && other.partialJson == partialJson;
  }

  @override
  int get hashCode => Object.hash(type, partialJson);

  @override
  String toString() => 'InputJsonDelta(partialJson: $partialJson)';
}

/// A delta containing incremental thinking content.
///
/// During streaming with extended thinking enabled, thinking content
/// is sent incrementally.
///
/// Example JSON:
/// ```json
/// {"type": "thinking_delta", "thinking": "Let me consider..."}
/// ```
@immutable
class ThinkingDelta extends Delta {
  /// The incremental thinking text.
  final String thinking;

  @override
  String get type => 'thinking_delta';

  /// Creates a [ThinkingDelta] with the given [thinking].
  const ThinkingDelta({required this.thinking});

  /// Creates a [ThinkingDelta] from a JSON map.
  factory ThinkingDelta.fromJson(Map<String, dynamic> json) {
    return ThinkingDelta(thinking: json['thinking'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {'type': type, 'thinking': thinking};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingDelta && other.thinking == thinking;
  }

  @override
  int get hashCode => Object.hash(type, thinking);

  @override
  String toString() => 'ThinkingDelta(thinking: $thinking)';
}

// ---------------------------------------------------------------------------
// MessageDelta
// ---------------------------------------------------------------------------

/// Represents the delta payload in a `message_delta` event.
///
/// Contains the [stopReason] indicating why the model stopped generating.
///
/// Example JSON:
/// ```json
/// {"stop_reason": "end_turn"}
/// ```
@immutable
class MessageDelta {
  /// The reason the model stopped generating, or `null` if not yet stopped.
  final StopReason? stopReason;

  /// Creates a [MessageDelta] with the given [stopReason].
  const MessageDelta({this.stopReason});

  /// Creates a [MessageDelta] from a JSON map.
  factory MessageDelta.fromJson(Map<String, dynamic> json) {
    final stopReasonValue = json['stop_reason'];
    return MessageDelta(
      stopReason: stopReasonValue != null
          ? StopReason.fromString(stopReasonValue as String)
          : null,
    );
  }

  /// Converts this [MessageDelta] to a JSON map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (stopReason != null) {
      json['stop_reason'] = stopReason!.toJson();
    }
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageDelta && other.stopReason == stopReason;
  }

  @override
  int get hashCode => stopReason.hashCode;

  @override
  String toString() => 'MessageDelta(stopReason: $stopReason)';
}

// ---------------------------------------------------------------------------
// MessageStreamEvent hierarchy
// ---------------------------------------------------------------------------

/// Base sealed class for all streaming events from the Anthropic Messages API.
///
/// When using `createStream()`, the API sends a sequence of Server-Sent Events
/// (SSE) that are parsed into [MessageStreamEvent] subclasses:
///
/// | `type` value             | Dart class                  |
/// |--------------------------|-----------------------------|
/// | `message_start`          | [MessageStartEvent]         |
/// | `content_block_start`    | [ContentBlockStartEvent]    |
/// | `content_block_delta`    | [ContentBlockDeltaEvent]    |
/// | `content_block_stop`     | [ContentBlockStopEvent]     |
/// | `message_delta`          | [MessageDeltaEvent]         |
/// | `message_stop`           | [MessageStopEvent]          |
///
/// Example SSE sequence:
/// ```
/// event: message_start
/// data: {"type":"message_start","message":{...}}
///
/// event: content_block_start
/// data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}
///
/// event: content_block_delta
/// data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}
///
/// event: content_block_stop
/// data: {"type":"content_block_stop","index":0}
///
/// event: message_delta
/// data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":15}}
///
/// event: message_stop
/// data: {"type":"message_stop"}
/// ```
@immutable
sealed class MessageStreamEvent {
  /// The event type identifier.
  String get type;

  const MessageStreamEvent();

  /// Creates the appropriate [MessageStreamEvent] subclass from a JSON map.
  ///
  /// Dispatches based on the `type` field in the JSON.
  /// Throws [ArgumentError] if the type is not recognised.
  factory MessageStreamEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'message_start' => MessageStartEvent.fromJson(json),
      'content_block_start' => ContentBlockStartEvent.fromJson(json),
      'content_block_delta' => ContentBlockDeltaEvent.fromJson(json),
      'content_block_stop' => ContentBlockStopEvent.fromJson(json),
      'message_delta' => MessageDeltaEvent.fromJson(json),
      'message_stop' => MessageStopEvent.fromJson(json),
      _ => throw ArgumentError('Unknown stream event type: $type'),
    };
  }
}

// ---------------------------------------------------------------------------
// MessageStartEvent
// ---------------------------------------------------------------------------

/// Event sent at the start of a streaming response.
///
/// Contains the initial [Message] object with metadata (id, model, role)
/// but typically with empty content and `null` stop_reason.
///
/// Example JSON:
/// ```json
/// {
///   "type": "message_start",
///   "message": {
///     "id": "msg_01",
///     "role": "assistant",
///     "content": [],
///     "model": "claude-sonnet-4-20250514",
///     "stop_reason": null,
///     "usage": {"input_tokens": 25, "output_tokens": 1}
///   }
/// }
/// ```
@immutable
class MessageStartEvent extends MessageStreamEvent {
  /// The initial message object (may have null stop_reason and empty content).
  final Message message;

  @override
  String get type => 'message_start';

  /// Creates a [MessageStartEvent] with the given [message].
  const MessageStartEvent({required this.message});

  /// Creates a [MessageStartEvent] from a JSON map.
  ///
  /// The `message` field is parsed flexibly to handle partial message objects
  /// where `stop_reason` may be `null`.
  factory MessageStartEvent.fromJson(Map<String, dynamic> json) {
    final messageJson = json['message'] as Map<String, dynamic>;
    return MessageStartEvent(
      message: _parsePartialMessage(messageJson),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageStartEvent && other.message == message;
  }

  @override
  int get hashCode => Object.hash(type, message);

  @override
  String toString() => 'MessageStartEvent(message: $message)';
}

// ---------------------------------------------------------------------------
// ContentBlockStartEvent
// ---------------------------------------------------------------------------

/// Event sent when a new content block begins in the stream.
///
/// Contains the [index] of the content block and the initial
/// [contentBlock] (typically with empty/default content).
///
/// Example JSON:
/// ```json
/// {
///   "type": "content_block_start",
///   "index": 0,
///   "content_block": {"type": "text", "text": ""}
/// }
/// ```
@immutable
class ContentBlockStartEvent extends MessageStreamEvent {
  /// The zero-based index of this content block in the message.
  final int index;

  /// The initial content block (may have empty/default values).
  final ContentBlock contentBlock;

  @override
  String get type => 'content_block_start';

  /// Creates a [ContentBlockStartEvent] with the given [index] and
  /// [contentBlock].
  const ContentBlockStartEvent({
    required this.index,
    required this.contentBlock,
  });

  /// Creates a [ContentBlockStartEvent] from a JSON map.
  factory ContentBlockStartEvent.fromJson(Map<String, dynamic> json) {
    final blockJson = json['content_block'] as Map<String, dynamic>;
    return ContentBlockStartEvent(
      index: json['index'] as int,
      contentBlock: _parseStreamContentBlock(blockJson),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentBlockStartEvent &&
        other.index == index &&
        other.contentBlock == contentBlock;
  }

  @override
  int get hashCode => Object.hash(type, index, contentBlock);

  @override
  String toString() =>
      'ContentBlockStartEvent(index: $index, contentBlock: $contentBlock)';
}

// ---------------------------------------------------------------------------
// ContentBlockDeltaEvent
// ---------------------------------------------------------------------------

/// Event sent when incremental content is available for a content block.
///
/// Contains the [index] of the content block and the [delta] with
/// the incremental content.
///
/// Example JSON:
/// ```json
/// {
///   "type": "content_block_delta",
///   "index": 0,
///   "delta": {"type": "text_delta", "text": "Hello"}
/// }
/// ```
@immutable
class ContentBlockDeltaEvent extends MessageStreamEvent {
  /// The zero-based index of the content block being updated.
  final int index;

  /// The incremental content delta.
  final Delta delta;

  @override
  String get type => 'content_block_delta';

  /// Creates a [ContentBlockDeltaEvent] with the given [index] and [delta].
  const ContentBlockDeltaEvent({
    required this.index,
    required this.delta,
  });

  /// Creates a [ContentBlockDeltaEvent] from a JSON map.
  factory ContentBlockDeltaEvent.fromJson(Map<String, dynamic> json) {
    return ContentBlockDeltaEvent(
      index: json['index'] as int,
      delta: Delta.fromJson(json['delta'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentBlockDeltaEvent &&
        other.index == index &&
        other.delta == delta;
  }

  @override
  int get hashCode => Object.hash(type, index, delta);

  @override
  String toString() =>
      'ContentBlockDeltaEvent(index: $index, delta: $delta)';
}

// ---------------------------------------------------------------------------
// ContentBlockStopEvent
// ---------------------------------------------------------------------------

/// Event sent when a content block is complete.
///
/// Example JSON:
/// ```json
/// {"type": "content_block_stop", "index": 0}
/// ```
@immutable
class ContentBlockStopEvent extends MessageStreamEvent {
  /// The zero-based index of the completed content block.
  final int index;

  @override
  String get type => 'content_block_stop';

  /// Creates a [ContentBlockStopEvent] with the given [index].
  const ContentBlockStopEvent({required this.index});

  /// Creates a [ContentBlockStopEvent] from a JSON map.
  factory ContentBlockStopEvent.fromJson(Map<String, dynamic> json) {
    return ContentBlockStopEvent(index: json['index'] as int);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentBlockStopEvent && other.index == index;
  }

  @override
  int get hashCode => Object.hash(type, index);

  @override
  String toString() => 'ContentBlockStopEvent(index: $index)';
}

// ---------------------------------------------------------------------------
// MessageDeltaEvent
// ---------------------------------------------------------------------------

/// Event sent near the end of a streaming response with final metadata.
///
/// Contains the [delta] with the stop reason and updated [usage] information.
///
/// Example JSON:
/// ```json
/// {
///   "type": "message_delta",
///   "delta": {"stop_reason": "end_turn"},
///   "usage": {"output_tokens": 15}
/// }
/// ```
@immutable
class MessageDeltaEvent extends MessageStreamEvent {
  /// The message delta containing the stop reason.
  final MessageDelta delta;

  /// Updated usage information (typically output_tokens).
  final Usage usage;

  @override
  String get type => 'message_delta';

  /// Creates a [MessageDeltaEvent] with the given [delta] and [usage].
  const MessageDeltaEvent({
    required this.delta,
    required this.usage,
  });

  /// Creates a [MessageDeltaEvent] from a JSON map.
  ///
  /// The `usage` field in `message_delta` events may only contain
  /// `output_tokens`. Missing `input_tokens` defaults to `0`.
  factory MessageDeltaEvent.fromJson(Map<String, dynamic> json) {
    final usageJson = json['usage'] as Map<String, dynamic>;
    return MessageDeltaEvent(
      delta: MessageDelta.fromJson(json['delta'] as Map<String, dynamic>),
      usage: Usage(
        inputTokens: usageJson['input_tokens'] as int? ?? 0,
        outputTokens: usageJson['output_tokens'] as int,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageDeltaEvent &&
        other.delta == delta &&
        other.usage == usage;
  }

  @override
  int get hashCode => Object.hash(type, delta, usage);

  @override
  String toString() => 'MessageDeltaEvent(delta: $delta, usage: $usage)';
}

// ---------------------------------------------------------------------------
// MessageStopEvent
// ---------------------------------------------------------------------------

/// Event sent when the streaming response is complete.
///
/// This is always the last event in a streaming sequence.
///
/// Example JSON:
/// ```json
/// {"type": "message_stop"}
/// ```
@immutable
class MessageStopEvent extends MessageStreamEvent {
  @override
  String get type => 'message_stop';

  /// Creates a [MessageStopEvent].
  const MessageStopEvent();

  /// Creates a [MessageStopEvent] from a JSON map.
  // ignore: avoid_unused_constructor_parameters
  factory MessageStopEvent.fromJson(Map<String, dynamic> json) {
    return const MessageStopEvent();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageStopEvent;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'MessageStopEvent()';
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Parses a partial [Message] from JSON, handling `null` stop_reason.
///
/// During streaming, the `message_start` event contains a message object
/// where `stop_reason` is `null` (the model hasn't stopped yet). This
/// helper defaults `stop_reason` to [StopReason.endTurn] when null.
Message _parsePartialMessage(Map<String, dynamic> json) {
  final contentList = json['content'] as List<dynamic>? ?? [];
  final content = contentList
      .map((item) => _parseStreamContentBlock(item as Map<String, dynamic>))
      .toList();

  final stopReasonValue = json['stop_reason'];
  final stopReason = stopReasonValue != null
      ? StopReason.fromString(stopReasonValue as String)
      : StopReason.endTurn;

  return Message(
    id: json['id'] as String,
    role: json['role'] as String,
    content: content,
    model: json['model'] as String,
    stopReason: stopReason,
    usage: Usage.fromJson(json['usage'] as Map<String, dynamic>),
  );
}

/// Parses a content block from streaming JSON.
///
/// Handles the content block types that appear in streaming events,
/// including partial blocks (e.g. empty text in `content_block_start`).
/// For `tool_use` blocks in streaming, `input` may be absent or empty.
ContentBlock _parseStreamContentBlock(Map<String, dynamic> json) {
  final type = json['type'] as String;
  return switch (type) {
    'text' => TextBlock(text: json['text'] as String? ?? ''),
    'tool_use' => ToolUseBlock(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        input: json['input'] != null
            ? Map<String, dynamic>.from(json['input'] as Map)
            : const {},
      ),
    'thinking' => ThinkingBlock(
        thinking: json['thinking'] as String? ?? '',
        signature: json['signature'] as String? ?? '',
      ),
    _ => TextBlock(text: '[unknown block type: $type]'),
  };
}
