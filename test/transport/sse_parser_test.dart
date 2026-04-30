import 'package:test/test.dart';

import 'package:anthropic_sdk_dart/src/transport/sse_parser.dart';

void main() {
  late SseParser parser;

  setUp(() {
    parser = const SseParser();
  });

  group('SseParser', () {
    test('parses a single event with event type and data', () async {
      final lines = Stream.fromIterable([
        'event: message_start',
        'data: {"type":"message_start"}',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('message_start'));
      expect(events[0].data, equals('{"type":"message_start"}'));
    });

    test('parses multiple events separated by empty lines', () async {
      final lines = Stream.fromIterable([
        'event: message_start',
        'data: {"type":"message_start","message":{}}',
        '',
        'event: content_block_delta',
        'data: {"type":"content_block_delta","index":0}',
        '',
        'event: message_stop',
        'data: {"type":"message_stop"}',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(3));
      expect(events[0].event, equals('message_start'));
      expect(events[1].event, equals('content_block_delta'));
      expect(events[2].event, equals('message_stop'));
    });

    test('defaults event type to "message" when no event line', () async {
      final lines = Stream.fromIterable([
        'data: {"type":"ping"}',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('message'));
      expect(events[0].data, equals('{"type":"ping"}'));
    });

    test('joins multiple data lines with newlines', () async {
      final lines = Stream.fromIterable([
        'event: multi_data',
        'data: line one',
        'data: line two',
        'data: line three',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('multi_data'));
      expect(events[0].data, equals('line one\nline two\nline three'));
    });

    test('ignores comment lines starting with ":"', () async {
      final lines = Stream.fromIterable([
        ': this is a comment',
        'event: message_start',
        ': another comment',
        'data: {"type":"message_start"}',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('message_start'));
      expect(events[0].data, equals('{"type":"message_start"}'));
    });

    test('ignores unknown field lines', () async {
      final lines = Stream.fromIterable([
        'event: test_event',
        'id: 12345',
        'retry: 3000',
        'data: hello',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('test_event'));
      expect(events[0].data, equals('hello'));
    });

    test('does not emit event when only empty lines (no data)', () async {
      final lines = Stream.fromIterable([
        '',
        '',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, isEmpty);
    });

    test('does not emit event for event-only line without data', () async {
      final lines = Stream.fromIterable([
        'event: no_data_event',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, isEmpty);
    });

    test('strips single leading space after colon in event field', () async {
      final lines = Stream.fromIterable([
        'event: spaced_event',
        'data: spaced data',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events[0].event, equals('spaced_event'));
      expect(events[0].data, equals('spaced data'));
    });

    test('handles no space after colon', () async {
      final lines = Stream.fromIterable([
        'event:no_space',
        'data:no_space_data',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events[0].event, equals('no_space'));
      expect(events[0].data, equals('no_space_data'));
    });

    test('emits final event when stream ends without trailing empty line',
        () async {
      final lines = Stream.fromIterable([
        'event: final_event',
        'data: {"last":true}',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('final_event'));
      expect(events[0].data, equals('{"last":true}'));
    });

    test('handles realistic Anthropic SSE stream', () async {
      final lines = Stream.fromIterable([
        'event: message_start',
        'data: {"type":"message_start","message":{"id":"msg_01","role":"assistant","content":[],"model":"claude-sonnet-4-20250514","stop_reason":null,"usage":{"input_tokens":25,"output_tokens":1}}}',
        '',
        'event: content_block_start',
        'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}',
        '',
        'event: content_block_delta',
        'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}',
        '',
        'event: content_block_delta',
        'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" world"}}',
        '',
        'event: content_block_stop',
        'data: {"type":"content_block_stop","index":0}',
        '',
        'event: message_delta',
        'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":15}}',
        '',
        'event: message_stop',
        'data: {"type":"message_stop"}',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(7));
      expect(events[0].event, equals('message_start'));
      expect(events[1].event, equals('content_block_start'));
      expect(events[2].event, equals('content_block_delta'));
      expect(events[3].event, equals('content_block_delta'));
      expect(events[4].event, equals('content_block_stop'));
      expect(events[5].event, equals('message_delta'));
      expect(events[6].event, equals('message_stop'));
    });

    test('handles data with empty string value', () async {
      final lines = Stream.fromIterable([
        'event: empty_data',
        'data: ',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('empty_data'));
      expect(events[0].data, equals(''));
    });

    test('handles data field with no value (just "data:")', () async {
      final lines = Stream.fromIterable([
        'event: bare_data',
        'data:',
        '',
      ]);

      final events = await parser.parse(lines).toList();

      expect(events, hasLength(1));
      expect(events[0].event, equals('bare_data'));
      expect(events[0].data, equals(''));
    });
  });

  group('SseEvent', () {
    test('equality works correctly', () {
      const a = SseEvent(event: 'test', data: 'hello');
      const b = SseEvent(event: 'test', data: 'hello');
      const c = SseEvent(event: 'test', data: 'world');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = SseEvent(event: 'test', data: 'hello');
      const b = SseEvent(event: 'test', data: 'hello');

      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns readable representation', () {
      const event = SseEvent(event: 'message_start', data: '{"type":"test"}');

      expect(
        event.toString(),
        equals('SseEvent(event: message_start, data: {"type":"test"})'),
      );
    });
  });
}
