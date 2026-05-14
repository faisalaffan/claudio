import 'claudio_exception.dart';

/// Thrown on 429 — rate limit exceeded.
class RateLimitException extends ClaudioException {
  final Duration? retryAfter;
  const RateLimitException(super.message, {super.statusCode, super.requestId, this.retryAfter});
}
