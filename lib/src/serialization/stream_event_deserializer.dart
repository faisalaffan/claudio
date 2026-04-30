import 'dart:async';
import 'dart:convert';

import '../models/content_block.dart';
import '../models/message.dart';
import '../models/stream_event.dart';
import '../models/usage.dart';
import '../transport/sse_parser.dart';

/// Bridges the SSE transport layer with the typed stream event model layer.
///
/// [StreamEventDeserializer] takes raw [SseEvent]s produced by [SseParser]
/// and converts them into strongly-typed [MessageStreamEvent] objects.
/// It also provides a convenience method to collect an entire stream of
/// events into a single [Message] object.
///
/// Example usage:
/// ```dart
/// final deserializer = StreamEventDeserializer();
/// final sseEvents = sseParser.parse(lines);
/// final typedEvents = deserializer.deserializeStream(sseEvents);
///
/// // Option 1: listen to individual events
/// await for (final event in typedEvents) {
///   print(event);
/// }
///
/// // Option 2: collect into a complete Message
/// final message = await StreamEventDeserializer.collectStream(typedEvents);
/// ```
class StreamEventDeserializer {
  /// Creates a [StreamEventDeserializer].
  const StreamEventDeserializer();

  /// Transforms a [Stream] of raw [SseEvent]s into a [Stream] of typed
  /// [MessageStreamEvent]s.
  ///
  /// Each [SseEvent] is processed as follows:
  /// 1. Events with type `"ping"` or `"error"` are silently skipped.
  /// 2. The [SseEvent.data] field is parsed as JSON.
  /// 3. The resulting JSON map is passed to [MessageStreamEvent.fromJson].
  ///
  /// Any JSON parse errors or unknown event types will propagate as
  /// exceptions through the stream.
  Stream<MessageStreamEvent> deserializeStream(
    Stream<SseEvent> sseEvents,
  ) {
    return sseEvents.transform(
      StreamTransformer<SseEvent, MessageStreamEvent>.fromHandlers(
        handleData: (sseEvent, sink) {
          // Skip ping and error events.
          if (sseEvent.event == 'ping' || sseEvent.event == 'error') {
            return;
          }

          final json = jsonDecode(sseEvent.data) as Map<String, dynamic>;
          final event = MessageStreamEvent.fromJson(json);
          sink.add(event);
        },
      ),
    );
  }

  /// Collects a stream of [MessageStreamEvent]s into a single [Message].
  ///
  /// Accumulates content from the event sequence:
  /// 1. [MessageStartEvent] — stores message metadata (id, model, role,
  ///    initial usage).
  /// 2. [ContentBlockStartEvent] — starts a new content block at the
  ///    given index.
  /// 3. [ContentBlockDeltaEvent] — appends incremental content:
  ///    - [TextDelta]: appends text to the [TextBlock] at that index.
  ///    - [InputJsonDelta]: appends partial JSON to the [ToolUseBlock]
  ///      accumulator at that index.
  ///    - [ThinkingDelta]: appends thinking text to the [ThinkingBlock]
  ///      at that index.
  /// 4. [ContentBlockStopEvent] — finalises the content block (for
  ///    [ToolUseBlock], parses the accumulated JSON into the `input` map).
  /// 5. [MessageDeltaEvent] — updates stop_reason and usage.
  /// 6. [MessageStopEvent] — builds and returns the final [Message].
  ///
  /// Throws [StateError] if the stream ends without a [MessageStopEvent].
  static Future<Message> collectStream(
    Stream<MessageStreamEvent> events,
  ) async {
    // Message metadata from MessageStartEvent.
    var id = '';
    var role = 'assistant';
    var model = '';
    var usage = const Usage(inputTokens: 0, outputTokens: 0);
    var stopReason = StopReason.endTurn;

    // Content block accumulators, indexed by block position.
    final contentBlocks = <int, ContentBlock>{};
    final textBuffers = <int, StringBuffer>{};
    final jsonBuffers = <int, StringBuffer>{};
    final thinkingBuffers = <int, StringBuffer>{};

    // Track block metadata for ToolUseBlock reconstruction.
    final toolUseIds = <int, String>{};
    final toolUseNames = <int, String>{};

    // Track ThinkingBlock signatures.
    final thinkingSignatures = <int, String>{};

    var messageStopReceived = false;

    await for (final event in events) {
      switch (event) {
        case MessageStartEvent(:final message):
          id = message.id;
          role = message.role;
          model = message.model;
          usage = message.usage;

        case ContentBlockStartEvent(:final index, :final contentBlock):
          switch (contentBlock) {
            case TextBlock():
              textBuffers[index] = StringBuffer(contentBlock.text);
              contentBlocks[index] = contentBlock;
            case ToolUseBlock():
              toolUseIds[index] = contentBlock.id;
              toolUseNames[index] = contentBlock.name;
              jsonBuffers[index] = StringBuffer();
              contentBlocks[index] = contentBlock;
            case ThinkingBlock():
              thinkingBuffers[index] =
                  StringBuffer(contentBlock.thinking);
              thinkingSignatures[index] = contentBlock.signature;
              contentBlocks[index] = contentBlock;
            default:
              // Store other block types as-is.
              contentBlocks[index] = contentBlock;
          }

        case ContentBlockDeltaEvent(:final index, :final delta):
          switch (delta) {
            case TextDelta(:final text):
              textBuffers[index]?.write(text);
            case InputJsonDelta(:final partialJson):
              jsonBuffers[index]?.write(partialJson);
            case ThinkingDelta(:final thinking):
              thinkingBuffers[index]?.write(thinking);
          }

        case ContentBlockStopEvent(:final index):
          // Finalise content blocks with accumulated data.
          if (textBuffers.containsKey(index)) {
            contentBlocks[index] =
                TextBlock(text: textBuffers[index]!.toString());
          } else if (jsonBuffers.containsKey(index)) {
            final jsonStr = jsonBuffers[index]!.toString();
            final input = jsonStr.isNotEmpty
                ? Map<String, dynamic>.from(
                    jsonDecode(jsonStr) as Map,
                  )
                : const <String, dynamic>{};
            contentBlocks[index] = ToolUseBlock(
              id: toolUseIds[index] ?? '',
              name: toolUseNames[index] ?? '',
              input: input,
            );
          } else if (thinkingBuffers.containsKey(index)) {
            contentBlocks[index] = ThinkingBlock(
              thinking: thinkingBuffers[index]!.toString(),
              signature: thinkingSignatures[index] ?? '',
            );
          }

        case MessageDeltaEvent(:final delta, usage: final updatedUsage):
          if (delta.stopReason != null) {
            stopReason = delta.stopReason!;
          }
          usage = Usage(
            inputTokens: usage.inputTokens,
            outputTokens: updatedUsage.outputTokens,
          );

        case MessageStopEvent():
          messageStopReceived = true;
      }
    }

    if (!messageStopReceived) {
      throw StateError(
        'Stream ended without receiving a MessageStopEvent',
      );
    }

    // Build the ordered content list from the indexed map.
    final sortedIndices = contentBlocks.keys.toList()..sort();
    final content = sortedIndices
        .map((index) => contentBlocks[index]!)
        .toList();

    return Message(
      id: id,
      role: role,
      content: content,
      model: model,
      stopReason: stopReason,
      usage: usage,
    );
  }
}
