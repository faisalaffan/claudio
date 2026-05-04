import 'claudio_exception.dart';

class InvalidRequestException extends ClaudioException {
  const InvalidRequestException(super.message, {super.statusCode, super.requestId});
}
