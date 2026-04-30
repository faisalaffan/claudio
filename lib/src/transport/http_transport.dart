import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../exceptions/exceptions.dart';
import 'retry_handler.dart';
import 'sse_parser.dart';

/// Internal HTTP transport layer that wraps `package:http` [http.Client]
/// and handles request execution, header management, error mapping,
/// and retry logic.
///
/// This class is not part of the public API — it is used internally by
/// [MessagesApi] to communicate with the Anthropic API.
///
/// Every request includes the required headers:
/// - `x-api-key` — the API key for authentication
/// - `anthropic-version` — the API version string
/// - `content-type` — always `application/json`
///
/// Error responses are mapped to the appropriate [AnthropicException]
/// subclass based on HTTP status code:
/// - 401 → [AuthenticationException]
/// - 429 → [RateLimitException] (with `retry-after` if available)
/// - 400 → [InvalidRequestException]
/// - 5xx → [ApiException]
///
/// Network-level failures (DNS, connection refused, timeout) are
/// wrapped in [NetworkException].
class HttpTransport {
  /// The underlying HTTP client used for all requests.
  final http.Client _client;

  /// The API key sent in the `x-api-key` header.
  final String _apiKey;

  /// The base URL for the Anthropic API (e.g. `https://api.anthropic.com`).
  final String _baseUrl;

  /// The API version sent in the `anthropic-version` header.
  final String _apiVersion;

  /// The retry handler for automatic retry on transient failures.
  final RetryHandler _retryHandler;

  /// Creates an [HttpTransport] with the given configuration.
  ///
  /// - [client]: The `package:http` client to use for requests.
  /// - [apiKey]: The Anthropic API key.
  /// - [baseUrl]: The base URL (no trailing slash).
  /// - [apiVersion]: The `anthropic-version` header value.
  /// - [retryHandler]: The retry handler for transient failure retry.
  HttpTransport({
    required http.Client client,
    required String apiKey,
    required String baseUrl,
    String apiVersion = '2023-06-01',
    required RetryHandler retryHandler,
  })  : _client = client,
        _apiKey = apiKey,
        _baseUrl = baseUrl,
        _apiVersion = apiVersion,
        _retryHandler = retryHandler;

  /// Common headers sent with every request.
  Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'anthropic-version': _apiVersion,
        'content-type': 'application/json',
      };

  /// Sends a POST request to [path] with the given JSON [body] and
  /// returns the parsed JSON response.
  ///
  /// The request is executed through [RetryHandler] for automatic
  /// retry on transient failures (429, 5xx, network errors).
  ///
  /// Throws the appropriate [AnthropicException] subclass if the
  /// response status code indicates an error.
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _retryHandler.executeWithRetry(() async {
      final http.Response response;
      try {
        response = await _client.post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        );
      } on SocketException catch (e) {
        throw NetworkException(message: e.message);
      } on TimeoutException catch (e) {
        throw NetworkException(
          message: e.message ?? 'Request timed out',
        );
      } on HttpException catch (e) {
        throw NetworkException(message: e.message);
      } on http.ClientException catch (e) {
        throw NetworkException(message: e.message);
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw _mapStatusCodeToException(
        statusCode: response.statusCode,
        responseBody: response.body,
        responseHeaders: response.headers,
      );
    });
  }

  /// Sends a POST request to [path] with the given JSON [body] and
  /// returns a [Stream] of [SseEvent]s for streaming responses.
  ///
  /// The caller is expected to have already set `"stream": true` in
  /// the [body]. This method uses [http.Client.send] to obtain a
  /// streamed response, then pipes the byte stream through [SseParser].
  ///
  /// If the response status code is not 200, the full body is read
  /// and the appropriate exception is thrown.
  ///
  /// Network-level failures are wrapped in [NetworkException].
  Stream<SseEvent> postStream(
    String path,
    Map<String, dynamic> body,
  ) {
    // Use a StreamController to bridge the async setup with the
    // synchronous Stream return type.
    late StreamController<SseEvent> controller;
    StreamSubscription<SseEvent>? subscription;

    controller = StreamController<SseEvent>(
      onCancel: () {
        subscription?.cancel();
      },
    );

    _startStream(path, body, controller).then(
      (sub) {
        subscription = sub;
      },
      onError: (Object error, StackTrace stackTrace) {
        controller.addError(error, stackTrace);
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Internal helper that initiates the streamed HTTP request and
  /// wires the SSE parser to the [controller].
  Future<StreamSubscription<SseEvent>> _startStream(
    String path,
    Map<String, dynamic> body,
    StreamController<SseEvent> controller,
  ) async {
    final http.StreamedResponse streamedResponse;
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl$path'));
      request.headers.addAll(_headers);
      request.body = jsonEncode(body);

      streamedResponse = await _client.send(request);
    } on SocketException catch (e) {
      throw NetworkException(message: e.message);
    } on TimeoutException catch (e) {
      throw NetworkException(message: e.message ?? 'Request timed out');
    } on HttpException catch (e) {
      throw NetworkException(message: e.message);
    } on http.ClientException catch (e) {
      throw NetworkException(message: e.message);
    }

    // If the status code is not 200, read the full body and throw.
    if (streamedResponse.statusCode != 200) {
      final responseBody = await streamedResponse.stream.bytesToString();
      throw _mapStatusCodeToException(
        statusCode: streamedResponse.statusCode,
        responseBody: responseBody,
        responseHeaders: streamedResponse.headers,
      );
    }

    // Split the byte stream into lines and parse as SSE events.
    const parser = SseParser();
    final lineStream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final sseStream = parser.parse(lineStream);

    final subscription = sseStream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );

    return subscription;
  }

  /// Releases the underlying HTTP client and its resources.
  void close() {
    _client.close();
  }

  /// Maps an HTTP status code to the appropriate [AnthropicException]
  /// subclass.
  ///
  /// Parses the Anthropic error response body format:
  /// ```json
  /// {"type": "error", "error": {"type": "...", "message": "..."}}
  /// ```
  ///
  /// Extracts the `request-id` header from the response for debugging.
  AnthropicException _mapStatusCodeToException({
    required int statusCode,
    required String responseBody,
    required Map<String, String> responseHeaders,
  }) {
    final errorMessage = _parseErrorMessage(responseBody);
    final requestId = responseHeaders['request-id'];

    switch (statusCode) {
      case 401:
        return AuthenticationException(
          message: errorMessage,
          statusCode: statusCode,
          requestId: requestId,
        );
      case 429:
        return RateLimitException(
          message: errorMessage,
          statusCode: statusCode,
          requestId: requestId,
          retryAfter: _parseRetryAfter(responseHeaders),
        );
      case 400:
        return InvalidRequestException(
          message: errorMessage,
          statusCode: statusCode,
          requestId: requestId,
        );
      default:
        if (statusCode >= 500 && statusCode <= 599) {
          return ApiException(
            message: errorMessage,
            statusCode: statusCode,
            requestId: requestId,
          );
        }
        // Fallback for unexpected status codes.
        return ApiException(
          message: errorMessage,
          statusCode: statusCode,
          requestId: requestId,
        );
    }
  }

  /// Parses the error message from the Anthropic API error response body.
  ///
  /// Expected format:
  /// ```json
  /// {"type": "error", "error": {"type": "...", "message": "..."}}
  /// ```
  ///
  /// Returns the `error.message` field if present, otherwise falls back
  /// to the raw response body.
  String _parseErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      if (error != null) {
        final message = error['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } on FormatException {
      // Response body is not valid JSON — use it as-is.
    }
    return responseBody.isNotEmpty ? responseBody : 'Unknown error';
  }

  /// Parses the `retry-after` header value into a [Duration].
  ///
  /// The header value is expected to be an integer number of seconds.
  /// Returns `null` if the header is absent or cannot be parsed.
  Duration? _parseRetryAfter(Map<String, String> headers) {
    final retryAfterValue = headers['retry-after'];
    if (retryAfterValue == null) {
      return null;
    }
    final seconds = int.tryParse(retryAfterValue);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
    return null;
  }
}
