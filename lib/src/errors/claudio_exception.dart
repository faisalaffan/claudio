/// Base class for all claudio exceptions.
abstract class ClaudioException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  const ClaudioException(this.message, {this.statusCode, this.requestId});

  @override
  String toString() => '${runtimeType}: $message';
}
