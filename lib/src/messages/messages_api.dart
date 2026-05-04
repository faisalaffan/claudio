import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'create_request.dart';
import 'message_response.dart';
import '../errors/claudio_exception.dart';
import '../errors/stream_exception.dart';
import '../http/http_client.dart';
import '../providers/provider_adapter.dart';
import '../streaming/sse_decoder.dart';
import '../streaming/stream_events.dart';

class MessagesApi {
  final ClaudioHttpClient _httpClient;
  final ProviderAdapter _adapter;
  final String _apiKey;

  MessagesApi({
    required ClaudioHttpClient httpClient,
    required ProviderAdapter adapter,
    required String apiKey,
  })  : _httpClient = httpClient,
        _adapter = adapter,
        _apiKey = apiKey;

  Future<Message> create(CreateMessageRequest request) async {
    _adapter.validateRequest(request);

    final response = await _httpClient.post(
      _adapter,
      _apiKey,
      '/v1/messages',
      request.toJson(),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Message.fromJson(json);
  }

  Stream<MessageStreamEvent> createStream(CreateMessageRequest request) async* {
    _adapter.validateRequest(request);

    final uri = _adapter.buildUri('/v1/messages');
    final headers = _adapter.buildHeaders(_apiKey);
    final body = jsonEncode(request.toStreamJson());

    final client = http.Client();
    try {
      final streamedRequest = http.Request('POST', uri);
      headers.forEach((k, v) => streamedRequest.headers[k] = v);
      streamedRequest.body = body;

      final streamedResponse = await client.send(streamedRequest);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.transform(utf8.decoder).join();
        throw StreamException(
          'Stream connection failed (${streamedResponse.statusCode}): $errorBody',
        );
      }

      final decoder = SseDecoder(streamedResponse.stream);
      await for (final eventJson in decoder.events) {
        final json = jsonDecode(eventJson) as Map<String, dynamic>;
        final event = _parseStreamEvent(json);
        if (event != null) yield event;
      }

      yield const MessageStopEvent();
    } on ClaudioException {
      rethrow;
    } catch (e) {
      throw StreamException('Stream error: $e');
    } finally {
      client.close();
    }
  }

  MessageStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    return switch (json['type'] as String?) {
      'message_start' => MessageStartEvent(
          message: Message.fromJson(json['message'] as Map<String, dynamic>)),
      'content_block_delta' => _parseContentBlockDelta(json),
      'message_delta' => MessageDeltaEvent(
          delta: StreamStopDelta(
            stopReason: (json['delta'] as Map)['stop_reason'] as String,
            stopSequence: (json['delta'] as Map)['stop_sequence'] as String?,
          ),
          usage: UsageDelta(
            outputTokens: (json['usage'] as Map)['output_tokens'] as int,
          ),
        ),
      'message_stop' => const MessageStopEvent(),
      _ => null,
    };
  }

  ContentBlockDeltaEvent _parseContentBlockDelta(Map<String, dynamic> json) {
    final index = json['index'] as int;
    final delta = json['delta'] as Map<String, dynamic>;
    final deltaType = delta['type'] as String;

    final contentDelta = switch (deltaType) {
      'text_delta' => TextDelta(text: delta['text'] as String),
      'input_json_delta' => InputJsonDelta(partialJson: delta['partial_json'] as String),
      'thinking_delta' => ThinkingDelta(thinking: delta['thinking'] as String),
      _ => throw StreamException('Unknown delta type: $deltaType'),
    };

    return ContentBlockDeltaEvent(index: index, delta: contentDelta);
  }
}
