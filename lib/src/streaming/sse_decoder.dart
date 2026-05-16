import 'dart:async';
import 'dart:convert';

/// Decodes Server-Sent Events from a byte stream.
class SseDecoder {
  final Stream<String> _lines;

  SseDecoder(Stream<List<int>> byteStream)
      : _lines = byteStream
            .map((bytes) => utf8.decode(bytes))
            .transform(const LineSplitter());

  Stream<String> get events => _lines.map((line) {
        if (line.startsWith('data: ')) {
          return line.substring(6);
        }
        return '';
      }).where((data) => data.isNotEmpty && data != '[DONE]');
}
