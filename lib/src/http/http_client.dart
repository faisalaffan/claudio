import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../client/retry_policy.dart';
import '../errors/api_exception.dart';
import '../errors/authentication_exception.dart';
import '../errors/invalid_request_exception.dart';
import '../errors/network_exception.dart';
import '../errors/rate_limit_exception.dart';
import '../providers/provider_adapter.dart';

/// Low-level HTTP client with retry and error handling.
class ClaudioHttpClient {
  final http.Client _inner;
  final RetryPolicy _retryPolicy;
  final Duration _timeout;

  ClaudioHttpClient({
    required http.Client inner,
    required RetryPolicy retryPolicy,
    required Duration timeout,
  })  : _inner = inner,
        _retryPolicy = retryPolicy,
        _timeout = timeout;

  Future<http.Response> post(
    ProviderAdapter adapter,
    String apiKey,
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = adapter.buildUri(path);
    final headers = adapter.buildHeaders(apiKey);
    final bodyBytes = jsonEncode(body);

    Exception? lastError;

    for (var attempt = 0; attempt <= _retryPolicy.maxRetries; attempt++) {
      try {
        final response = await _inner
            .post(uri, headers: headers, body: bodyBytes)
            .timeout(_timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        final exception = _handleErrorResponse(response);

        if (!_shouldRetry(response.statusCode)) {
          throw exception;
        }

        lastError = exception;
      } on http.ClientException catch (e) {
        lastError = NetworkException(e.message);
      } on TimeoutException {
        lastError = const NetworkException('Request timed out');
      }

      if (attempt < _retryPolicy.maxRetries) {
        await Future<void>.delayed(_retryPolicy.delayForAttempt(attempt));
      }
    }

    throw lastError!;
  }

  bool _shouldRetry(int statusCode) => statusCode == 429 || statusCode >= 500;

  Exception _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;
    String? requestId;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        requestId = decoded['request_id'] as String?;
      }
    } catch (_) {}

    return switch (statusCode) {
      401 => AuthenticationException(body,
          statusCode: statusCode, requestId: requestId),
      429 => RateLimitException(body,
          statusCode: statusCode,
          requestId: requestId,
          retryAfter: _parseRetryAfter(response.headers['retry-after'])),
      400 => InvalidRequestException(body,
          statusCode: statusCode, requestId: requestId),
      _ => ApiException(body, statusCode: statusCode, requestId: requestId),
    };
  }

  Duration? _parseRetryAfter(String? value) {
    if (value == null) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) return Duration(seconds: seconds);
    return null;
  }

  void close() => _inner.close();
}
