import 'dart:math';

/// Configuration for automatic retry with exponential backoff.
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;

  const RetryPolicy({
    this.maxRetries = 2,
    this.initialDelay = const Duration(seconds: 1),
  });

  /// Compute delay for attempt [n] (0-indexed).
  Duration delayForAttempt(int attempt) {
    final base = initialDelay.inMilliseconds * pow(2, attempt).toInt();
    final jitter = Random().nextInt(1000);
    return Duration(milliseconds: base + jitter);
  }
}
