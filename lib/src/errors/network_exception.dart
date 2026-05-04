import 'claudio_exception.dart';

class NetworkException extends ClaudioException {
  const NetworkException(super.message, {super.statusCode, super.requestId});
}
