import 'package:meta/meta.dart';

/// Base exception class for all Anthropic SDK errors.
///
/// Contains common fields shared by all exception types:
/// - [message]: Human-readable error description
/// - [statusCode]: HTTP status code (if applicable)
/// - [requestId]: Request ID from the API response header (if available)
@immutable
class AnthropicException implements Exception {
  /// Human-readable error description.
  final String message;

  /// HTTP status code associated with the error, if applicable.
  final int? statusCode;

  /// Request ID from the `request-id` response header, if available.
  /// Useful for debugging and support requests.
  final String? requestId;

  /// Creates an [AnthropicException] with the given [message],
  /// optional [statusCode], and optional [requestId].
  const AnthropicException({
    required this.message,
    this.statusCode,
    this.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AnthropicException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}

/// Thrown when the API key is invalid or missing (HTTP 401).
@immutable
class AuthenticationException extends AnthropicException {
  /// Creates an [AuthenticationException] with the given [message],
  /// optional [statusCode], and optional [requestId].
  const AuthenticationException({
    required super.message,
    super.statusCode,
    super.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AuthenticationException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}

/// Thrown when the API rate limit is exceeded (HTTP 429).
///
/// May include a [retryAfter] duration indicating how long to wait
/// before retrying the request, parsed from the `retry-after` header.
@immutable
class RateLimitException extends AnthropicException {
  /// Duration to wait before retrying, parsed from the `retry-after`
  /// response header. May be `null` if the header is not present.
  final Duration? retryAfter;

  /// Creates a [RateLimitException] with the given [message],
  /// optional [retryAfter] duration, optional [statusCode],
  /// and optional [requestId].
  const RateLimitException({
    required super.message,
    this.retryAfter,
    super.statusCode,
    super.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('RateLimitException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (retryAfter != null) {
      buffer.write(' (retry after: ${retryAfter!.inSeconds}s)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}

/// Thrown when the request body is invalid (HTTP 400).
@immutable
class InvalidRequestException extends AnthropicException {
  /// Creates an [InvalidRequestException] with the given [message],
  /// optional [statusCode], and optional [requestId].
  const InvalidRequestException({
    required super.message,
    super.statusCode,
    super.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('InvalidRequestException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}

/// Thrown when the API returns a server error (HTTP 5xx).
@immutable
class ApiException extends AnthropicException {
  /// Creates an [ApiException] with the given [message],
  /// optional [statusCode], and optional [requestId].
  const ApiException({
    required super.message,
    super.statusCode,
    super.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}

/// Thrown when a network error occurs (DNS failure, connection refused,
/// timeout, etc.).
@immutable
class NetworkException extends AnthropicException {
  /// Creates a [NetworkException] with the given [message],
  /// optional [statusCode], and optional [requestId].
  const NetworkException({
    required super.message,
    super.statusCode,
    super.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('NetworkException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}

/// Thrown when an SSE streaming connection is lost or encounters an error.
@immutable
class StreamException extends AnthropicException {
  /// Creates a [StreamException] with the given [message],
  /// optional [statusCode], and optional [requestId].
  const StreamException({
    required super.message,
    super.statusCode,
    super.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('StreamException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}

/// Thrown when the client is used after [AnthropicClient.close] has been called.
@immutable
class ClientClosedException extends AnthropicException {
  /// Creates a [ClientClosedException] with the given [message],
  /// optional [statusCode], and optional [requestId].
  const ClientClosedException({
    required super.message,
    super.statusCode,
    super.requestId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ClientClosedException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (requestId != null) {
      buffer.write(' [request-id: $requestId]');
    }
    return buffer.toString();
  }
}
