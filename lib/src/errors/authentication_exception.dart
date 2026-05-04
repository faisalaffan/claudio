import 'claudio_exception.dart';

class AuthenticationException extends ClaudioException {
  const AuthenticationException(super.message, {super.statusCode, super.requestId});
}
