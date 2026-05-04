import 'claudio_exception.dart';

class ClientClosedException extends ClaudioException {
  const ClientClosedException() : super('Client has been closed');
}
