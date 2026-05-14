import 'dart:convert';
import 'package:claudio_sdk/src/client/retry_policy.dart';
import 'package:claudio_sdk/src/errors/authentication_exception.dart';
import 'package:claudio_sdk/src/http/http_client.dart';
import 'package:claudio_sdk/src/messages/create_request.dart';
import 'package:claudio_sdk/src/messages/message_param.dart';
import 'package:claudio_sdk/src/messages/messages_api.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../test_helpers.mocks.dart';

void main() {
  group('MessagesApi.create', () {
    late MockClient mockHttp;
    late ClaudioHttpClient claudioHttp;
    late MockProviderAdapter adapter;
    late MessagesApi api;

    setUp(() {
      mockHttp = MockClient();
      adapter = MockProviderAdapter();
      when(adapter.buildUri(any)).thenReturn(Uri.parse('https://api.test.com/v1/messages'));
      when(adapter.buildHeaders(any)).thenReturn({'x-api-key': 'test-key', 'content-type': 'application/json'});

      claudioHttp = ClaudioHttpClient(
        inner: mockHttp,
        retryPolicy: const RetryPolicy(maxRetries: 0),
        timeout: const Duration(seconds: 5),
      );

      api = MessagesApi(httpClient: claudioHttp, adapter: adapter, apiKey: 'test-key');
    });

    test('returns Message on success', () async {
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(jsonEncode({
            'id': 'msg_123', 'model': 'test-model', 'stop_reason': 'end_turn',
            'usage': {'input_tokens': 10, 'output_tokens': 20},
            'content': [{'type': 'text', 'text': 'Hello!'}],
          }), 200));

      final request = CreateMessageRequest(
        model: 'test-model', maxTokens: 100,
        messages: [MessageParam(role: 'user', content: 'Hi')],
      );

      final message = await api.create(request);
      expect(message.id, 'msg_123');
      expect(message.text, 'Hello!');
    });

    test('throws on error response', () async {
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));

      final request = CreateMessageRequest(model: 'test', maxTokens: 100, messages: []);
      expect(() => api.create(request), throwsA(isA<AuthenticationException>()));
    });

    tearDown(() {
      claudioHttp.close();
    });
  });
}
