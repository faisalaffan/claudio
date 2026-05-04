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

    test('delayForAttempt includes jitter', () {
      const policy = RetryPolicy();
      final delays = List.generate(10, (i) => policy.delayForAttempt(0));
      final unique = delays.toSet();
      expect(unique.length, greaterThan(1));
    });
  });
}
