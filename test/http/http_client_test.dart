import 'package:claudio_sdk/src/client/retry_policy.dart';
import 'package:claudio_sdk/src/errors/authentication_exception.dart';
import 'package:claudio_sdk/src/http/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../test_helpers.mocks.dart';

void main() {
  group('ClaudioHttpClient', () {
    late MockClient mockHttp;
    late ClaudioHttpClient claudioHttp;
    late MockProviderAdapter adapter;

    setUp(() {
      mockHttp = MockClient();
      adapter = MockProviderAdapter();
      when(adapter.buildUri('/v1/messages'))
          .thenReturn(Uri.parse('https://api.test.com/v1/messages'));
      when(adapter.buildHeaders('key'))
          .thenReturn({'authorization': 'Bearer test'});

      claudioHttp = ClaudioHttpClient(
        inner: mockHttp,
        retryPolicy: const RetryPolicy(maxRetries: 1, initialDelay: Duration(milliseconds: 10)),
        timeout: const Duration(seconds: 5),
      );
    });

    test('successful response returns http.Response', () async {
      when(mockHttp.post(
        Uri.parse('https://api.test.com/v1/messages'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"id":"ok"}', 200));
      final response = await claudioHttp.post(adapter, 'key', '/v1/messages', {'test': true});
      expect(response.statusCode, 200);
      expect(response.body, '{"id":"ok"}');
    });

    test('throws AuthenticationException on 401', () async {
      when(mockHttp.post(
        Uri.parse('https://api.test.com/v1/messages'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Unauthorized', 401));
      expect(
        () => claudioHttp.post(adapter, 'key', '/v1/messages', {}),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('retries on 429 then succeeds', () async {
      var calls = 0;
      when(mockHttp.post(
        Uri.parse('https://api.test.com/v1/messages'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        calls++;
        if (calls == 1) return http.Response('Rate limited', 429);
        return http.Response('{"id":"ok"}', 200);
      });
      final response = await claudioHttp.post(adapter, 'key', '/v1/messages', {});
      expect(response.statusCode, 200);
      expect(calls, 2);
    });

    tearDown(() {
      claudioHttp.close();
    });
  });
}
