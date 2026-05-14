import 'package:claudio_sdk/src/client/claudio_client.dart';
import 'package:claudio_sdk/src/client/provider.dart';
import 'package:claudio_sdk/src/client/retry_policy.dart';
import 'package:claudio_sdk/src/errors/client_closed_exception.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudioClient', () {
    test('creates with required params', () {
      final client = ClaudioClient(apiKey: 'sk-test', provider: Provider.anthropic);
      expect(client.provider, Provider.anthropic);
      client.close();
    });

    test('creates with custom retry policy', () {
      final client = ClaudioClient(
        apiKey: 'sk-test',
        provider: Provider.deepseek,
        timeout: const Duration(seconds: 30),
        retryPolicy: const RetryPolicy(maxRetries: 5),
      );
      expect(client.provider, Provider.deepseek);
      client.close();
    });

    test('throws ClientClosedException after close', () {
      final client = ClaudioClient(apiKey: 'sk-test', provider: Provider.anthropic);
      client.close();
      expect(() => client.messages, throwsA(isA<ClientClosedException>()));
    });

    test('provider returns correct value', () {
      final client = ClaudioClient(apiKey: 'sk-test', provider: Provider.deepseek);
      expect(client.provider, Provider.deepseek);
      client.close();
    });
  });
}
