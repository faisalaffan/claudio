import 'package:meta/meta.dart';

/// Configuration for extended thinking in API requests.
///
/// Extended thinking allows the model to show its reasoning process
/// before providing a final answer. This is configured via the `thinking`
/// parameter in a [CreateMessageRequest].
///
/// Use the factory constructors to create the appropriate variant:
/// - [ThinkingConfig.enabled] — enables thinking with a token budget
/// - [ThinkingConfig.disabled] — explicitly disables thinking
/// - [ThinkingConfig.adaptive] — lets the API decide adaptively
///
/// Example JSON outputs:
/// ```json
/// {"type": "enabled", "budget_tokens": 4096}
/// {"type": "disabled"}
/// {"type": "adaptive"}
/// ```
@immutable
sealed class ThinkingConfig {
  /// The type identifier for JSON serialization.
  String get type;

  const ThinkingConfig();

  /// Creates a [ThinkingConfig] that enables extended thinking with the
  /// given [budgetTokens] limit.
  factory ThinkingConfig.enabled({required int budgetTokens}) =
      ThinkingConfigEnabled;

  /// Creates a [ThinkingConfig] that explicitly disables extended thinking.
  factory ThinkingConfig.disabled() = ThinkingConfigDisabled;

  /// Creates a [ThinkingConfig] that lets the API decide adaptively
  /// whether to use extended thinking.
  factory ThinkingConfig.adaptive() = ThinkingConfigAdaptive;

  /// Converts this [ThinkingConfig] to a JSON map.
  Map<String, dynamic> toJson();
}

/// Extended thinking is enabled with a token budget.
///
/// The [budgetTokens] field specifies the maximum number of tokens
/// the model may use for its thinking process.
@immutable
class ThinkingConfigEnabled extends ThinkingConfig {
  /// The maximum number of tokens allocated for the thinking process.
  final int budgetTokens;

  @override
  String get type => 'enabled';

  /// Creates a [ThinkingConfigEnabled] with the given [budgetTokens].
  const ThinkingConfigEnabled({required this.budgetTokens});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'budget_tokens': budgetTokens,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingConfigEnabled &&
        other.budgetTokens == budgetTokens;
  }

  @override
  int get hashCode => Object.hash(type, budgetTokens);

  @override
  String toString() => 'ThinkingConfig.enabled(budgetTokens: $budgetTokens)';
}

/// Extended thinking is explicitly disabled.
@immutable
class ThinkingConfigDisabled extends ThinkingConfig {
  @override
  String get type => 'disabled';

  /// Creates a [ThinkingConfigDisabled].
  const ThinkingConfigDisabled();

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingConfigDisabled;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'ThinkingConfig.disabled()';
}

/// Extended thinking is adaptive — the API decides whether to use it.
@immutable
class ThinkingConfigAdaptive extends ThinkingConfig {
  @override
  String get type => 'adaptive';

  /// Creates a [ThinkingConfigAdaptive].
  const ThinkingConfigAdaptive();

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingConfigAdaptive;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'ThinkingConfig.adaptive()';
}
