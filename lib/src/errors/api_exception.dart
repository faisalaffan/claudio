import 'claudio_exception.dart';

/// Thrown when the API returns a 5xx or unexpected error.
class ApiException extends ClaudioException {
  const ApiException(super.message, {super.statusCode, super.requestId});
}
