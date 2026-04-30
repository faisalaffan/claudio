import 'dart:math';

import 'package:meta/meta.dart';

import '../exceptions/exceptions.dart';

/// Configuration for automatic retry behavior on transient failures.
///
/// Controls how many times a failed request is retried and the initial
/// delay between attempts. The actual delay uses exponential backoff
/// with jitter: `initialDelay * 2^attempt + jitter`.
@immutable
class RetryPolicy {
  /// Maximum number of retry attempts after the initial request.
  /// Defaults to 2 (so up to 3 total attempts).
  final int maxRetries;

  /// Base delay for the first retry. Subsequent retries double this value.
  /// Defaults to 1 second.
  final Duration initialDelay;

  /// Creates a [RetryPolicy] with the given [maxRetries] and [initialDelay].
  const RetryPolicy({
    this.maxRetries = 2,
    this.initialDelay = const Duration(seconds: 1),
  });
}

/// Wraps async actions with automatic retry logic using exponential backoff.
///
/// Retries are performed only for transient errors:
/// - HTTP 429 (rate limit) — respects `retry-after` header
/// - HTTP 5xx (server errors)
/// - [NetworkException] (DNS, connection, timeout)
///
/// Non-retryable errors (400, 401) are thrown immediately.
/// After all retries are exhausted, the exception from the **last** attempt
/// is thrown.
class RetryHandler {
  /// The retry policy controlling max attempts and base delay.
  final RetryPolicy policy;

  /// Injectable delay function for testing. Defaults to [Future.delayed].
  final Future<void> Function(Duration) _delayFn;

  /// Injectable random jitter function for testing.
  /// Returns a value in [0, 1). Defaults to [Random.nextDouble].
  final double Function() _jitterFn;

  /// Creates a [RetryHandler] with the given [policy].
  ///
  /// [delayFn] and [jitterFn] can be injected for deterministic testing.
  RetryHandler({
    RetryPolicy? policy,
    Future<void> Function(Duration)? delayFn,
    double Function()? jitterFn,
  })  : policy = policy ?? const RetryPolicy(),
        _delayFn = delayFn ?? Future.delayed,
        _jitterFn = jitterFn ?? Random().nextDouble;

  /// Executes [action] with automatic retry on transient failures.
  ///
  /// The action is called up to `policy.maxRetries + 1` times total.
  /// If all attempts fail, the exception from the last attempt is thrown.
  Future<T> executeWithRetry<T>(Future<T> Function() action) async {
    AnthropicException? lastException;

    for (var attempt = 0; attempt <= policy.maxRetries; attempt++) {
      try {
        return await action();
      } on AnthropicException catch (e) {
        if (!_isRetryable(e)) {
          rethrow;
        }

        lastException = e;

        // Don't delay after the last attempt — just throw.
        if (attempt < policy.maxRetries) {
          final delay = _calculateDelay(attempt, e);
          await _delayFn(delay);
        }
      }
    }

    // All retries exhausted — throw the last exception.
    throw lastException!;
  }

  /// Returns `true` if the exception represents a transient error
  /// that should be retried.
  bool _isRetryable(AnthropicException exception) {
    // Network errors are always retryable.
    if (exception is NetworkException) {
      return true;
    }

    // Rate limit (429) is retryable.
    if (exception is RateLimitException) {
      return true;
    }

    // Server errors (5xx) are retryable.
    if (exception is ApiException) {
      final code = exception.statusCode;
      if (code != null && code >= 500 && code <= 599) {
        return true;
      }
    }

    // Everything else (400, 401, stream errors, etc.) is not retryable.
    return false;
  }

  /// Calculates the delay before the next retry attempt.
  ///
  /// Uses exponential backoff: `initialDelay * 2^attempt + jitter`
  /// where jitter is a random duration between 0 and 1 second.
  ///
  /// For 429 responses with a `retry-after` header, the delay is the
  /// maximum of the calculated backoff and the retry-after value.
  Duration _calculateDelay(int attempt, AnthropicException exception) {
    // Exponential backoff: initialDelay * 2^attempt
    final backoffMs =
        policy.initialDelay.inMilliseconds * pow(2, attempt).toInt();

    // Jitter: random 0–1 second
    final jitterMs = (_jitterFn() * 1000).toInt();

    var delayMs = backoffMs + jitterMs;

    // For rate limit exceptions, respect retry-after if it's larger.
    if (exception is RateLimitException && exception.retryAfter != null) {
      final retryAfterMs = exception.retryAfter!.inMilliseconds;
      if (retryAfterMs > delayMs) {
        delayMs = retryAfterMs;
      }
    }

    return Duration(milliseconds: delayMs);
  }
}
