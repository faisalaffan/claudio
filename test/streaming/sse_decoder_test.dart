import 'dart:convert';
import 'package:claudio/src/streaming/sse_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('SseDecoder', () {
    test('parses data lines and ignores [DONE]', () async {
      final input = Stream.fromIterable([
        utf8.encode('event: message_start\ndata: {"type":"start"}\n\n'),
        utf8.encode('data: {"type":"delta"}\n\n'),
        utf8.encode('data: [DONE]\n\n'),
      ]);
      final decoder = SseDecoder(input);
      final events = await decoder.events.toList();
      expect(events, ['{"type":"start"}', '{"type":"delta"}']);
    });

    test('handles empty input', () async {
      final input = Stream<List<int>>.fromIterable([]);
      final decoder = SseDecoder(input);
      final events = await decoder.events.toList();
      expect(events, isEmpty);
    });

    test('ignores comments and empty data', () async {
      final input = Stream.fromIterable([
        utf8.encode('data: \n\n'),
        utf8.encode(':comment\n\n'),
        utf8.encode('data: {"real":"data"}\n\n'),
      ]);
      final decoder = SseDecoder(input);
      final events = await decoder.events.toList();
      expect(events, ['{"real":"data"}']);
    });
  });
}
