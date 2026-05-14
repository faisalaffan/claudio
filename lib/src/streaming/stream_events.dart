import '../messages/message_response.dart';

/// Base sealed class for all SSE stream events.
sealed class MessageStreamEvent {
  const MessageStreamEvent();
}

/// Stream has started. Contains initial message metadata.
class MessageStartEvent extends MessageStreamEvent {
  final Message message;
  const MessageStartEvent({required this.message});
}

/// An incremental content delta from the stream.
sealed class ContentDelta {
  const ContentDelta();
}

/// A chunk of text from the stream.
class TextDelta extends ContentDelta {
  final String text;
  const TextDelta({required this.text});
}

/// A partial JSON chunk for tool input.
class InputJsonDelta extends ContentDelta {
  final String partialJson;
  const InputJsonDelta({required this.partialJson});
}

/// A chunk of extended thinking output.
class ThinkingDelta extends ContentDelta {
  final String thinking;
  const ThinkingDelta({required this.thinking});
}

/// Emitted when a content block receives a delta update.
class ContentBlockDeltaEvent extends MessageStreamEvent {
  final int index;
  final ContentDelta delta;
  const ContentBlockDeltaEvent({required this.index, required this.delta});
}

/// Contains the stop reason and optional stop sequence.
class StreamStopDelta {
  final String stopReason;
  final String? stopSequence;
  const StreamStopDelta({required this.stopReason, this.stopSequence});
}

/// Token usage delta from the stream.
class UsageDelta {
  final int outputTokens;
  const UsageDelta({required this.outputTokens});
}

/// Emitted when the message stop reason or usage is updated.
class MessageDeltaEvent extends MessageStreamEvent {
  final StreamStopDelta delta;
  final UsageDelta usage;
  const MessageDeltaEvent({required this.delta, required this.usage});
}

/// Emitted when the stream completes successfully.
class MessageStopEvent extends MessageStreamEvent {
  const MessageStopEvent();
}
