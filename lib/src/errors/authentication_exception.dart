import 'claudio_exception.dart';

/// Thrown on 401 — invalid or missing API key.
class AuthenticationException extends ClaudioException {
  const AuthenticationException(super.message, {super.statusCode, super.requestId});
}
