import 'claudio_exception.dart';

/// Thrown on 400 — malformed request body or parameters.
class InvalidRequestException extends ClaudioException {
  const InvalidRequestException(super.message,
      {super.statusCode, super.requestId});
}
