import 'dart:async';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:anthropic_sdk_dart/src/serialization/stream_event_deserializer.dart';
import 'package:anthropic_sdk_dart/src/transport/sse_parser.dart';
import 'package:test/test.dart';

void main() {
  group('StreamEventDeserializer', () {
    late StreamEventDeserializer deserializer;

    setUp(() {
      deserializer = const StreamEventDeserializer();
    });

    group('deserializeStream', () {
      test('converts SSE events to MessageStreamEvents', () async {
        final sseEvents = Stream.fromIterable([
          const SseEvent(
            event: 'message_start',
            data: '{"type":"message_start","message":{'
                '"id":"msg_01","role":"assistant","content":[],'
                '"model":"claude-sonnet-4-20250514","stop_reason":null,'
                '"usage":{"input_tokens":10,"output_tokens":1}}}',
          ),
          const SseEvent(
            event: 'message_stop',
            data: '{"type":"message_stop"}',
          ),
        ]);

        final events =
            await deserializer.deserializeStream(sseEvents).toList();

        expect(events, hasLength(2));
        expect(events[0], isA<MessageStartEvent>());
        expect(events[1], isA<MessageStopEvent>());
      });

      test('skips ping events', () async {
        final sseEvents = Stream.fromIterable([
          const SseEvent(event: 'ping', data: '{}'),
          const SseEvent(
            event: 'message_stop',
            data: '{"type":"message_stop"}',
          ),
        ]);

        final events =
            await deserializer.deserializeStream(sseEvents).toList();

        expect(events, hasLength(1));
        expect(events[0], isA<MessageStopEvent>());
      });

      test('skips error events', () async {
        final sseEvents = Stream.fromIterable([
          const SseEvent(
            event: 'error',
            data: '{"type":"error","error":{"message":"oops"}}',
          ),
          const SseEvent(
            event: 'message_stop',
            data: '{"type":"message_stop"}',
          ),
        ]);

        final events =
            await deserializer.deserializeStream(sseEvents).toList();

        expect(events, hasLength(1));
        expect(events[0], isA<MessageStopEvent>());
      });

      test('parses content_block_delta with text delta', () async {
        final sseEvents = Stream.fromIterable([
          const SseEvent(
            event: 'content_block_delta',
            data: '{"type":"content_block_delta","index":0,'
                '"delta":{"type":"text_delta","text":"Hello"}}',
          ),
        ]);

        final events =
            await deserializer.deserializeStream(sseEvents).toList();

        expect(events, hasLength(1));
        final event = events[0] as ContentBlockDeltaEvent;
        expect(event.index, 0);
        expect(event.delta, isA<TextDelta>());
        expect((event.delta as TextDelta).text, 'Hello');
      });
    });

    group('collectStream', () {
      test('collects simple text message', () async {
        final events = Stream.fromIterable(<MessageStreamEvent>[
          MessageStartEvent(
            message: const Message(
              id: 'msg_01',
              role: 'assistant',
              content: [],
              model: 'claude-sonnet-4-20250514',
              stopReason: StopReason.endTurn,
              usage: Usage(inputTokens: 10, outputTokens: 1),
            ),
          ),
          const ContentBlockStartEvent(
            index: 0,
            contentBlock: TextBlock(text: ''),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: TextDelta(text: 'Hello'),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: TextDelta(text: ' world'),
          ),
          const ContentBlockStopEvent(index: 0),
          const MessageDeltaEvent(
            delta: MessageDelta(stopReason: StopReason.endTurn),
            usage: Usage(inputTokens: 0, outputTokens: 12),
          ),
          const MessageStopEvent(),
        ]);

        final message =
            await StreamEventDeserializer.collectStream(events);

        expect(message.id, 'msg_01');
        expect(message.role, 'assistant');
        expect(message.model, 'claude-sonnet-4-20250514');
        expect(message.stopReason, StopReason.endTurn);
        expect(message.usage.outputTokens, 12);
        expect(message.content, hasLength(1));
        expect(message.content[0], isA<TextBlock>());
        expect((message.content[0] as TextBlock).text, 'Hello world');
      });

      test('collects tool use message with JSON input', () async {
        final events = Stream.fromIterable(<MessageStreamEvent>[
          MessageStartEvent(
            message: const Message(
              id: 'msg_02',
              role: 'assistant',
              content: [],
              model: 'claude-sonnet-4-20250514',
              stopReason: StopReason.endTurn,
              usage: Usage(inputTokens: 20, outputTokens: 1),
            ),
          ),
          const ContentBlockStartEvent(
            index: 0,
            contentBlock: ToolUseBlock(
              id: 'toolu_01',
              name: 'get_weather',
              input: {},
            ),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: InputJsonDelta(partialJson: '{"loc'),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: InputJsonDelta(partialJson: 'ation":"SF"}'),
          ),
          const ContentBlockStopEvent(index: 0),
          const MessageDeltaEvent(
            delta: MessageDelta(stopReason: StopReason.toolUse),
            usage: Usage(inputTokens: 0, outputTokens: 25),
          ),
          const MessageStopEvent(),
        ]);

        final message =
            await StreamEventDeserializer.collectStream(events);

        expect(message.id, 'msg_02');
        expect(message.stopReason, StopReason.toolUse);
        expect(message.content, hasLength(1));
        final toolBlock = message.content[0] as ToolUseBlock;
        expect(toolBlock.id, 'toolu_01');
        expect(toolBlock.name, 'get_weather');
        expect(toolBlock.input, {'location': 'SF'});
      });

      test('collects thinking block', () async {
        final events = Stream.fromIterable(<MessageStreamEvent>[
          MessageStartEvent(
            message: const Message(
              id: 'msg_03',
              role: 'assistant',
              content: [],
              model: 'claude-sonnet-4-20250514',
              stopReason: StopReason.endTurn,
              usage: Usage(inputTokens: 10, outputTokens: 1),
            ),
          ),
          const ContentBlockStartEvent(
            index: 0,
            contentBlock: ThinkingBlock(thinking: '', signature: 'sig1'),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: ThinkingDelta(thinking: 'Let me think'),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: ThinkingDelta(thinking: ' about this...'),
          ),
          const ContentBlockStopEvent(index: 0),
          const ContentBlockStartEvent(
            index: 1,
            contentBlock: TextBlock(text: ''),
          ),
          const ContentBlockDeltaEvent(
            index: 1,
            delta: TextDelta(text: 'The answer is 42'),
          ),
          const ContentBlockStopEvent(index: 1),
          const MessageDeltaEvent(
            delta: MessageDelta(stopReason: StopReason.endTurn),
            usage: Usage(inputTokens: 0, outputTokens: 30),
          ),
          const MessageStopEvent(),
        ]);

        final message =
            await StreamEventDeserializer.collectStream(events);

        expect(message.content, hasLength(2));
        final thinking = message.content[0] as ThinkingBlock;
        expect(thinking.thinking, 'Let me think about this...');
        expect(thinking.signature, 'sig1');
        final text = message.content[1] as TextBlock;
        expect(text.text, 'The answer is 42');
      });

      test('collects mixed text and tool use blocks', () async {
        final events = Stream.fromIterable(<MessageStreamEvent>[
          MessageStartEvent(
            message: const Message(
              id: 'msg_04',
              role: 'assistant',
              content: [],
              model: 'claude-sonnet-4-20250514',
              stopReason: StopReason.endTurn,
              usage: Usage(inputTokens: 15, outputTokens: 1),
            ),
          ),
          const ContentBlockStartEvent(
            index: 0,
            contentBlock: TextBlock(text: ''),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: TextDelta(text: 'Let me check'),
          ),
          const ContentBlockStopEvent(index: 0),
          const ContentBlockStartEvent(
            index: 1,
            contentBlock: ToolUseBlock(
              id: 'toolu_02',
              name: 'search',
              input: {},
            ),
          ),
          const ContentBlockDeltaEvent(
            index: 1,
            delta: InputJsonDelta(partialJson: '{"query":"dart"}'),
          ),
          const ContentBlockStopEvent(index: 1),
          const MessageDeltaEvent(
            delta: MessageDelta(stopReason: StopReason.toolUse),
            usage: Usage(inputTokens: 0, outputTokens: 20),
          ),
          const MessageStopEvent(),
        ]);

        final message =
            await StreamEventDeserializer.collectStream(events);

        expect(message.content, hasLength(2));
        expect(message.content[0], isA<TextBlock>());
        expect((message.content[0] as TextBlock).text, 'Let me check');
        expect(message.content[1], isA<ToolUseBlock>());
        final tool = message.content[1] as ToolUseBlock;
        expect(tool.input, {'query': 'dart'});
      });

      test('throws StateError when stream ends without MessageStopEvent',
          () async {
        final events = Stream.fromIterable(<MessageStreamEvent>[
          MessageStartEvent(
            message: const Message(
              id: 'msg_05',
              role: 'assistant',
              content: [],
              model: 'claude-sonnet-4-20250514',
              stopReason: StopReason.endTurn,
              usage: Usage(inputTokens: 5, outputTokens: 1),
            ),
          ),
        ]);

        expect(
          () => StreamEventDeserializer.collectStream(events),
          throwsA(isA<StateError>()),
        );
      });

      test('handles tool use with empty input', () async {
        final events = Stream.fromIterable(<MessageStreamEvent>[
          MessageStartEvent(
            message: const Message(
              id: 'msg_06',
              role: 'assistant',
              content: [],
              model: 'claude-sonnet-4-20250514',
              stopReason: StopReason.endTurn,
              usage: Usage(inputTokens: 10, outputTokens: 1),
            ),
          ),
          const ContentBlockStartEvent(
            index: 0,
            contentBlock: ToolUseBlock(
              id: 'toolu_03',
              name: 'no_args_tool',
              input: {},
            ),
          ),
          // No InputJsonDelta events — empty input.
          const ContentBlockStopEvent(index: 0),
          const MessageDeltaEvent(
            delta: MessageDelta(stopReason: StopReason.toolUse),
            usage: Usage(inputTokens: 0, outputTokens: 5),
          ),
          const MessageStopEvent(),
        ]);

        final message =
            await StreamEventDeserializer.collectStream(events);

        final tool = message.content[0] as ToolUseBlock;
        expect(tool.id, 'toolu_03');
        expect(tool.name, 'no_args_tool');
        expect(tool.input, isEmpty);
      });

      test('preserves content block ordering', () async {
        final events = Stream.fromIterable(<MessageStreamEvent>[
          MessageStartEvent(
            message: const Message(
              id: 'msg_07',
              role: 'assistant',
              content: [],
              model: 'claude-sonnet-4-20250514',
              stopReason: StopReason.endTurn,
              usage: Usage(inputTokens: 10, outputTokens: 1),
            ),
          ),
          const ContentBlockStartEvent(
            index: 0,
            contentBlock: TextBlock(text: ''),
          ),
          const ContentBlockDeltaEvent(
            index: 0,
            delta: TextDelta(text: 'First'),
          ),
          const ContentBlockStopEvent(index: 0),
          const ContentBlockStartEvent(
            index: 1,
            contentBlock: TextBlock(text: ''),
          ),
          const ContentBlockDeltaEvent(
            index: 1,
            delta: TextDelta(text: 'Second'),
          ),
          const ContentBlockStopEvent(index: 1),
          const ContentBlockStartEvent(
            index: 2,
            contentBlock: TextBlock(text: ''),
          ),
          const ContentBlockDeltaEvent(
            index: 2,
            delta: TextDelta(text: 'Third'),
          ),
          const ContentBlockStopEvent(index: 2),
          const MessageDeltaEvent(
            delta: MessageDelta(stopReason: StopReason.endTurn),
            usage: Usage(inputTokens: 0, outputTokens: 10),
          ),
          const MessageStopEvent(),
        ]);

        final message =
            await StreamEventDeserializer.collectStream(events);

        expect(message.content, hasLength(3));
        expect((message.content[0] as TextBlock).text, 'First');
        expect((message.content[1] as TextBlock).text, 'Second');
        expect((message.content[2] as TextBlock).text, 'Third');
      });
    });
  });
}
