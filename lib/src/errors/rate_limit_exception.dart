import 'claudio_exception.dart';

class RateLimitException extends ClaudioException {
  final Duration? retryAfter;
  const RateLimitException(super.message, {super.statusCode, super.requestId, this.retryAfter});
}
