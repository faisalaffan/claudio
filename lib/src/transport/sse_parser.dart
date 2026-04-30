import 'dart:async';

import 'package:meta/meta.dart';

/// Represents a single parsed Server-Sent Event.
///
/// An SSE event consists of an [event] type (e.g. `"message_start"`,
/// `"content_block_delta"`) and a [data] payload (typically a JSON string).
///
/// If no `event:` line is present in the SSE stream before the empty-line
/// boundary, the event type defaults to `"message"`.
@immutable
class SseEvent {
  /// The event type, parsed from the `event:` field.
  /// Defaults to `"message"` when no explicit event type is provided.
  final String event;

  /// The data payload, parsed from one or more `data:` fields.
  /// Multiple `data:` lines are joined with newlines.
  final String data;

  /// Creates an [SseEvent] with the given [event] type and [data] payload.
  const SseEvent({required this.event, required this.data});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SseEvent &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          data == other.data;

  @override
  int get hashCode => event.hashCode ^ data.hashCode;

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

/// Parses a stream of text lines into a stream of [SseEvent]s following
/// the Server-Sent Events specification.
///
/// ## SSE Format Rules
///
/// 1. Lines starting with `event:` set the event type (prefix stripped).
/// 2. Lines starting with `data:` contain the data payload (prefix stripped).
/// 3. Empty lines mark the end of an event — the accumulated event is emitted.
/// 4. Lines starting with `:` are comments and are ignored.
/// 5. Multiple `data:` lines before an empty line are joined with newlines.
/// 6. If no `event:` line is present, the default event type is `"message"`.
///
/// Example usage:
/// ```dart
/// final parser = SseParser();
/// final events = parser.parse(linesStream);
/// await for (final event in events) {
///   print('${event.event}: ${event.data}');
/// }
/// ```
class SseParser {
  /// Creates an [SseParser].
  const SseParser();

  /// Transforms a [Stream] of text lines from an HTTP response into a
  /// [Stream] of parsed [SseEvent]s.
  ///
  /// Each line in the input stream should be a single line of the SSE
  /// response (without trailing newline characters). Empty strings
  /// represent blank lines that delimit events.
  Stream<SseEvent> parse(Stream<String> lines) {
    String? eventType;
    final dataLines = <String>[];

    return lines
        .transform(
          StreamTransformer<String, SseEvent>.fromHandlers(
            handleData: (line, sink) {
              // Comment lines start with ':' — ignore them.
              if (line.startsWith(':')) {
                return;
              }

              // Empty line marks the end of an event boundary.
              if (line.isEmpty) {
                // Only emit if we have accumulated data.
                if (dataLines.isNotEmpty) {
                  sink.add(SseEvent(
                    event: eventType ?? 'message',
                    data: dataLines.join('\n'),
                  ));
                }

                // Reset state for the next event.
                eventType = null;
                dataLines.clear();
                return;
              }

              // Parse 'event:' field.
              if (line.startsWith('event:')) {
                eventType = _stripPrefix(line, 'event:');
                return;
              }

              // Parse 'data:' field.
              if (line.startsWith('data:')) {
                dataLines.add(_stripPrefix(line, 'data:'));
                return;
              }

              // Unknown fields are ignored per the SSE specification.
            },
            handleDone: (sink) {
              // If the stream ends with accumulated data but no trailing
              // empty line, emit the final event.
              if (dataLines.isNotEmpty) {
                sink.add(SseEvent(
                  event: eventType ?? 'message',
                  data: dataLines.join('\n'),
                ));
              }
              sink.close();
            },
          ),
        );
  }

  /// Strips the [prefix] from [line] and trims a single leading space
  /// if present (per SSE spec: the space after the colon is optional
  /// but conventionally present).
  static String _stripPrefix(String line, String prefix) {
    final value = line.substring(prefix.length);
    if (value.startsWith(' ')) {
      return value.substring(1);
    }
    return value;
  }
}
