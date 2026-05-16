import 'package:claudio_sdk/src/client/provider.dart';
import 'package:test/test.dart';

void main() {
  group('Provider', () {
    test('has anthropic and deepseek values', () {
      expect(Provider.values,
          containsAll([Provider.anthropic, Provider.deepseek]));
    });

    test('Provider.anthropic name is "anthropic"', () {
      expect(Provider.anthropic.name, 'anthropic');
    });

    test('Provider.deepseek name is "deepseek"', () {
      expect(Provider.deepseek.name, 'deepseek');
    });
  });
}
