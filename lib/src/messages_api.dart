import 'dart:async';

import 'models/message.dart';
import 'models/request.dart';
import 'models/stream_event.dart';
import 'serialization/deserializer.dart';
import 'serialization/serializer.dart';
import 'serialization/stream_event_deserializer.dart';
import 'transport/http_transport.dart';

/// The path for the Messages API endpoint.
const _messagesPath = '/v1/messages';

/// Abstract interface for the Anthropic Messages API.
///
/// Provides two methods for creating messages:
/// - [create] for non-streaming (single response) requests.
/// - [createStream] for streaming (SSE) requests that yield events
///   incrementally.
///
/// Example:
/// ```dart
/// final message = await messagesApi.create(
///   CreateMessageRequest(
///     model: 'claude-sonnet-4-20250514',
///     maxTokens: 1024,
///     messages: [MessageParam(role: 'user', content: 'Hello!')],
///   ),
/// );
/// print(message.text);
/// ```
abstract class MessagesApi {
  /// Creates a message (non-streaming).
  ///
  /// Sends the [request] to the Anthropic Messages API and returns
  /// the complete [Message] response.
  ///
  /// Throws the appropriate [AnthropicException] subclass on failure.
  Future<Message> create(CreateMessageRequest request);

  /// Creates a message with streaming response.
  ///
  /// Sends the [request] to the Anthropic Messages API with streaming
  /// enabled and returns a [Stream] of [MessageStreamEvent]s.
  ///
  /// The stream can be cancelled at any time without resource leaks.
  ///
  /// Throws the appropriate [AnthropicException] subclass if the
  /// initial connection fails.
  Stream<MessageStreamEvent> createStream(CreateMessageRequest request);
}

/// Concrete implementation of [MessagesApi] that communicates with the
/// Anthropic Messages API via [HttpTransport].
///
/// Uses [Serializer] to convert request objects to JSON and
/// [Deserializer] / [StreamEventDeserializer] to convert responses
/// back to typed Dart objects.
///
/// This class is not intended to be instantiated directly by end users.
/// Instead, access it through [AnthropicClient.messages].
class MessagesApiImpl implements MessagesApi {
  /// The HTTP transport layer for sending requests.
  final HttpTransport _transport;

  /// Serializer for converting request models to JSON.
  final Serializer _serializer;

  /// Deserializer for converting JSON responses to model objects.
  final Deserializer _deserializer;

  /// Deserializer for converting SSE events to typed stream events.
  final StreamEventDeserializer _streamEventDeserializer;

  /// Creates a [MessagesApiImpl] with the given [transport].
  ///
  /// Optionally accepts custom [serializer], [deserializer], and
  /// [streamEventDeserializer] instances for testing. Defaults to
  /// standard implementations.
  MessagesApiImpl({
    required HttpTransport transport,
    Serializer serializer = const Serializer(),
    Deserializer deserializer = const Deserializer(),
    StreamEventDeserializer streamEventDeserializer =
        const StreamEventDeserializer(),
  })  : _transport = transport,
        _serializer = serializer,
        _deserializer = deserializer,
        _streamEventDeserializer = streamEventDeserializer;

  /// Creates a message using the non-streaming API.
  ///
  /// The [request] is serialized with `stream: false` and sent as a
  /// POST request to `/v1/messages`. The JSON response is deserialized
  /// into a [Message] object.
  ///
  /// Throws the appropriate [AnthropicException] subclass on failure
  /// (e.g. [AuthenticationException], [RateLimitException]).
  @override
  Future<Message> create(CreateMessageRequest request) async {
    // Ensure stream is false for non-streaming requests.
    final effectiveRequest = request.stream
        ? request.copyWith(stream: false)
        : request;

    final body = _serializer.serializeRequest(effectiveRequest);
    final responseJson = await _transport.post(_messagesPath, body);
    return _deserializer.deserializeMessage(responseJson);
  }

  /// Creates a message using the streaming API.
  ///
  /// The [request] is serialized with `stream: true` and sent as a
  /// POST request to `/v1/messages`. The SSE response is parsed and
  /// converted into a stream of typed [MessageStreamEvent]s.
  ///
  /// The returned stream can be cancelled at any time. Cancellation
  /// propagates through the SSE stream and HTTP connection, ensuring
  /// no resource leaks.
  ///
  /// Throws the appropriate [AnthropicException] subclass if the
  /// initial HTTP request fails.
  @override
  Stream<MessageStreamEvent> createStream(CreateMessageRequest request) {
    // Ensure stream is true for streaming requests.
    final effectiveRequest = request.stream
        ? request
        : request.copyWith(stream: true);

    final body = _serializer.serializeRequest(effectiveRequest);
    final sseStream = _transport.postStream(_messagesPath, body);
    return _streamEventDeserializer.deserializeStream(sseStream);
  }
}
