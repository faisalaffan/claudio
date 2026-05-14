import 'claudio_exception.dart';

/// Thrown when the SSE stream fails or returns an error status.
class StreamException extends ClaudioException {
  const StreamException(super.message, {super.statusCode, super.requestId});
}
