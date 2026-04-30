import 'package:test/test.dart';

import 'package:anthropic_sdk_dart/src/models/usage.dart';

void main() {
  group('Usage', () {
    test('creates instance with const constructor', () {
      const usage = Usage(inputTokens: 25, outputTokens: 15);
      expect(usage.inputTokens, equals(25));
      expect(usage.outputTokens, equals(15));
    });

    test('toJson() produces snake_case keys', () {
      const usage = Usage(inputTokens: 25, outputTokens: 15);
      final json = usage.toJson();

      expect(json, equals({'input_tokens': 25, 'output_tokens': 15}));
    });

    test('fromJson() parses snake_case keys', () {
      final usage = Usage.fromJson({
        'input_tokens': 100,
        'output_tokens': 50,
      });

      expect(usage.inputTokens, equals(100));
      expect(usage.outputTokens, equals(50));
    });

    test('round-trip toJson/fromJson preserves values', () {
      const original = Usage(inputTokens: 42, outputTokens: 99);
      final roundTripped = Usage.fromJson(original.toJson());

      expect(roundTripped, equals(original));
    });

    test('equality works correctly', () {
      const a = Usage(inputTokens: 10, outputTokens: 20);
      const b = Usage(inputTokens: 10, outputTokens: 20);
      const c = Usage(inputTokens: 10, outputTokens: 30);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString() returns readable representation', () {
      const usage = Usage(inputTokens: 25, outputTokens: 15);
      expect(
        usage.toString(),
        equals('Usage(inputTokens: 25, outputTokens: 15)'),
      );
    });
  });
}
