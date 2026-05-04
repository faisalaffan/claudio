import 'package:claudio/src/client/feature.dart';
import 'package:test/test.dart';

void main() {
  group('Feature', () {
    test('has all expected values', () {
      expect(Feature.values, containsAll([
        Feature.extendedThinking,
        Feature.imageInput,
        Feature.toolUse,
        Feature.streaming,
        Feature.systemPrompt,
        Feature.promptCaching,
      ]));
    });
  });
}
