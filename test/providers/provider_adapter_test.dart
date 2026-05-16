import 'package:claudio_sdk/src/client/feature.dart';
import 'package:claudio_sdk/src/client/provider.dart';
import 'package:claudio_sdk/src/errors/unsupported_feature_exception.dart';
import 'package:claudio_sdk/src/messages/create_request.dart';
import 'package:claudio_sdk/src/providers/anthropic_adapter.dart';
import 'package:claudio_sdk/src/providers/deepseek_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicAdapter', () {
    final adapter = AnthropicAdapter();

    test('provider is anthropic', () {
      expect(adapter.provider, Provider.anthropic);
    });

    test('baseUrl', () {
      expect(adapter.baseUrl, 'https://api.anthropic.com');
    });

    test('buildHeaders uses x-api-key', () {
      final headers = adapter.buildHeaders('sk-ant-test');
      expect(headers['x-api-key'], 'sk-ant-test');
      expect(headers['anthropic-version'], '2023-06-01');
      expect(headers['content-type'], 'application/json');
    });

    test('buildUri returns correct URI', () {
      final uri = adapter.buildUri('/v1/messages');
      expect(uri.toString(), 'https://api.anthropic.com/v1/messages');
    });

    test('supports all features', () {
      expect(
          adapter.supportedFeatures,
          containsAll([
            Feature.extendedThinking,
            Feature.imageInput,
            Feature.toolUse,
            Feature.streaming,
            Feature.systemPrompt,
            Feature.promptCaching,
          ]));
    });

    test('validateRequest does not throw for valid request', () {
      final request =
          CreateMessageRequest(model: 'test', maxTokens: 100, messages: []);
      expect(() => adapter.validateRequest(request), returnsNormally);
    });
  });

  group('DeepSeekAdapter', () {
    final adapter = DeepSeekAdapter();

    test('provider is deepseek', () {
      expect(adapter.provider, Provider.deepseek);
    });

    test('baseUrl', () {
      expect(adapter.baseUrl, 'https://api.deepseek.com');
    });

    test('buildHeaders uses Bearer auth', () {
      final headers = adapter.buildHeaders('sk-deepseek-test');
      expect(headers['Authorization'], 'Bearer sk-deepseek-test');
    });

    test('does NOT support extendedThinking', () {
      expect(
          adapter.supportedFeatures.contains(Feature.extendedThinking), false);
    });

    test('throws UnsupportedFeatureException for thinking', () {
      final request = CreateMessageRequest(
        model: 'deepseek-chat',
        maxTokens: 100,
        messages: [],
        thinking: const ThinkingConfig.enabled(),
      );
      expect(
        () => adapter.validateRequest(request),
        throwsA(isA<UnsupportedFeatureException>()),
      );
    });

    test('supports tool use, streaming, systemPrompt', () {
      expect(
          adapter.supportedFeatures,
          containsAll([
            Feature.toolUse,
            Feature.streaming,
            Feature.systemPrompt,
          ]));
    });
  });
}
