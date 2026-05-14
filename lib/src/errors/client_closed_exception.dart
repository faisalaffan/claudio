import 'claudio_exception.dart';

/// Thrown when attempting to use a closed [ClaudioClient].
class ClientClosedException extends ClaudioException {
  const ClientClosedException() : super('Client has been closed');
}
