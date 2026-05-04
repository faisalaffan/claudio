import 'claudio_exception.dart';

class StreamException extends ClaudioException {
  const StreamException(super.message, {super.statusCode, super.requestId});
}
