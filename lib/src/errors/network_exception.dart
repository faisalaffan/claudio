import 'claudio_exception.dart';

/// Thrown on connection failure or timeout.
class NetworkException extends ClaudioException {
  const NetworkException(super.message, {super.statusCode, super.requestId});
}
