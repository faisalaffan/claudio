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

class TextDelta extends ContentDelta {
  final String text;
  const TextDelta({required this.text});
}

class InputJsonDelta extends ContentDelta {
  final String partialJson;
  const InputJsonDelta({required this.partialJson});
}

class ThinkingDelta extends ContentDelta {
  final String thinking;
  const ThinkingDelta({required this.thinking});
}

class ContentBlockDeltaEvent extends MessageStreamEvent {
  final int index;
  final ContentDelta delta;
  const ContentBlockDeltaEvent({required this.index, required this.delta});
}

class StreamStopDelta {
  final String stopReason;
  final String? stopSequence;
  const StreamStopDelta({required this.stopReason, this.stopSequence});
}

class UsageDelta {
  final int outputTokens;
  const UsageDelta({required this.outputTokens});
}

class MessageDeltaEvent extends MessageStreamEvent {
  final StreamStopDelta delta;
  final UsageDelta usage;
  const MessageDeltaEvent({required this.delta, required this.usage});
}

class MessageStopEvent extends MessageStreamEvent {
  const MessageStopEvent();
}
