import 'package:anthropic_sdk_dart/src/models/thinking.dart';
import 'package:test/test.dart';

void main() {
  group('ThinkingConfig', () {
    group('enabled', () {
      test('creates ThinkingConfigEnabled with budgetTokens', () {
        final config = ThinkingConfig.enabled(budgetTokens: 4096);

        expect(config, isA<ThinkingConfigEnabled>());
        expect((config as ThinkingConfigEnabled).budgetTokens, 4096);
        expect(config.type, 'enabled');
      });

      test('toJson returns correct map', () {
        final config = ThinkingConfig.enabled(budgetTokens: 4096);

        expect(config.toJson(), {
          'type': 'enabled',
          'budget_tokens': 4096,
        });
      });

      test('equality works correctly', () {
        final a = ThinkingConfig.enabled(budgetTokens: 4096);
        final b = ThinkingConfig.enabled(budgetTokens: 4096);
        final c = ThinkingConfig.enabled(budgetTokens: 8192);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a, isNot(equals(c)));
      });

      test('toString returns readable representation', () {
        final config = ThinkingConfig.enabled(budgetTokens: 4096);
        expect(config.toString(),
            'ThinkingConfig.enabled(budgetTokens: 4096)');
      });
    });

    group('disabled', () {
      test('creates ThinkingConfigDisabled', () {
        final config = ThinkingConfig.disabled();

        expect(config, isA<ThinkingConfigDisabled>());
        expect(config.type, 'disabled');
      });

      test('toJson returns correct map', () {
        final config = ThinkingConfig.disabled();

        expect(config.toJson(), {'type': 'disabled'});
      });

      test('equality works correctly', () {
        final a = ThinkingConfig.disabled();
        final b = ThinkingConfig.disabled();

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('toString returns readable representation', () {
        final config = ThinkingConfig.disabled();
        expect(config.toString(), 'ThinkingConfig.disabled()');
      });
    });

    group('adaptive', () {
      test('creates ThinkingConfigAdaptive', () {
        final config = ThinkingConfig.adaptive();

        expect(config, isA<ThinkingConfigAdaptive>());
        expect(config.type, 'adaptive');
      });

      test('toJson returns correct map', () {
        final config = ThinkingConfig.adaptive();

        expect(config.toJson(), {'type': 'adaptive'});
      });

      test('equality works correctly', () {
        final a = ThinkingConfig.adaptive();
        final b = ThinkingConfig.adaptive();

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('toString returns readable representation', () {
        final config = ThinkingConfig.adaptive();
        expect(config.toString(), 'ThinkingConfig.adaptive()');
      });
    });

    group('sealed class exhaustiveness', () {
      test('switch expression covers all variants', () {
        final configs = <ThinkingConfig>[
          ThinkingConfig.enabled(budgetTokens: 1024),
          ThinkingConfig.disabled(),
          ThinkingConfig.adaptive(),
        ];

        for (final config in configs) {
          final label = switch (config) {
            ThinkingConfigEnabled() => 'enabled',
            ThinkingConfigDisabled() => 'disabled',
            ThinkingConfigAdaptive() => 'adaptive',
          };
          expect(label, config.type);
        }
      });
    });

    group('immutability', () {
      test('all variants are immutable (const constructors)', () {
        // These compile because const constructors exist
        const enabled = ThinkingConfigEnabled(budgetTokens: 2048);
        const disabled = ThinkingConfigDisabled();
        const adaptive = ThinkingConfigAdaptive();

        expect(enabled.budgetTokens, 2048);
        expect(disabled.type, 'disabled');
        expect(adaptive.type, 'adaptive');
      });
    });

    group('cross-variant inequality', () {
      test('different variants are not equal', () {
        final enabled = ThinkingConfig.enabled(budgetTokens: 1024);
        final disabled = ThinkingConfig.disabled();
        final adaptive = ThinkingConfig.adaptive();

        expect(enabled, isNot(equals(disabled)));
        expect(enabled, isNot(equals(adaptive)));
        expect(disabled, isNot(equals(adaptive)));
      });
    });
  });
}
