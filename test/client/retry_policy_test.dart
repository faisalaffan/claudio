import 'package:claudio/src/client/retry_policy.dart';
import 'package:test/test.dart';

void main() {
  group('RetryPolicy', () {
    test('has defaults', () {
      const policy = RetryPolicy();
      expect(policy.maxRetries, 2);
      expect(policy.initialDelay, const Duration(seconds: 1));
    });

    test('custom values', () {
      const policy = RetryPolicy(maxRetries: 5, initialDelay: Duration(seconds: 3));
      expect(policy.maxRetries, 5);
      expect(policy.initialDelay, const Duration(seconds: 3));
    });

    test('delayForAttempt increases exponentially', () {
      const policy = RetryPolicy(maxRetries: 3);
      final d0 = policy.delayForAttempt(0);
      final d1 = policy.delayForAttempt(1);
      final d2 = policy.delayForAttempt(2);
      expect(d1.inMilliseconds, greaterThan(d0.inMilliseconds));
      expect(d2.inMilliseconds, greaterThan(d1.inMilliseconds));
    });

    test('delayForAttempt includes jitter within expected range', () {
      const policy = RetryPolicy();
      const baseMs = 1000; // initialDelay = 1 second
      for (var i = 0; i < 20; i++) {
        final delay = policy.delayForAttempt(0);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(baseMs));
        expect(delay.inMilliseconds, lessThan(baseMs + 1000));
      }
    });

    test('delayForAttempt(0) returns approximately initialDelay plus jitter', () {
      const policy = RetryPolicy();
      final delay = policy.delayForAttempt(0);
      expect(delay.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(delay.inMilliseconds, lessThan(2000));
    });
  });
}
