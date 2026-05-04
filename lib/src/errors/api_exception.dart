import 'claudio_exception.dart';

class ApiException extends ClaudioException {
  const ApiException(super.message, {super.statusCode, super.requestId});
}
