import 'dart:io' show Platform;

import 'package:http/http.dart' as http;

import 'exceptions/exceptions.dart';
import 'messages_api.dart';
import 'transport/http_transport.dart';
import 'transport/retry_handler.dart';

/// The main entry point for the Anthropic SDK.
///
/// Provides access to the Anthropic Messages API through the [messages]
/// getter. Manages the underlying HTTP client, transport layer, and
/// retry logic.
///
/// ## Creating a client
///
/// ```dart
/// // With an explicit API key:
/// final client = AnthropicClient(apiKey: 'sk-ant-...');
///
/// // From the ANTHROPIC_API_KEY environment variable:
/// final client = AnthropicClient.fromEnvironment();
/// ```
///
/// ## Using the client
///
/// ```dart
/// final message = await client.messages.create(
///   CreateMessageRequest(
///     model: 'claude-sonnet-4-20250514',
///     maxTokens: 1024,
///     messages: [MessageParam(role: 'user', content: 'Hello!')],
///   ),
/// );
/// print(message.text);
/// ```
///
/// ## Closing the client
///
/// Always call [close] when the client is no longer needed to release
/// HTTP resources:
///
/// ```dart
/// client.close();
/// ```
///
/// Using the client after calling [close] throws [ClientClosedException].
class AnthropicClient {
  /// The HTTP transport layer used for API communication.
  final HttpTransport _transport;

  /// The configured request timeout.
  // ignore: unused_field
  final Duration _timeout;

  /// The lazily-created [MessagesApi] instance.
  late final MessagesApiImpl _messagesApi;

  /// Whether [close] has been called.
  bool _closed = false;

  /// Internal constructor used by the public factory constructors.
  AnthropicClient._({
    required HttpTransport transport,
    required Duration timeout,
  })  : _transport = transport,
        _timeout = timeout {
    _messagesApi = MessagesApiImpl(transport: _transport);
  }

  /// Creates an [AnthropicClient] with an explicit [apiKey].
  ///
  /// Optional parameters:
  /// - [baseUrl]: The Anthropic API base URL. Defaults to
  ///   `https://api.anthropic.com`.
  /// - [timeout]: The HTTP request timeout. Defaults to 120 seconds.
  /// - [retryPolicy]: The retry policy for transient failures. If
  ///   `null`, a default [RetryPolicy] is used.
  /// - [httpClient]: An optional `package:http` [http.Client] for
  ///   testing. If `null`, a new client is created internally.
  factory AnthropicClient({
    required String apiKey,
    String baseUrl = 'https://api.anthropic.com',
    Duration timeout = const Duration(seconds: 120),
    RetryPolicy? retryPolicy,
    http.Client? httpClient,
  }) {
    final client = httpClient ?? http.Client();
    final retryHandler = RetryHandler(policy: retryPolicy);
    final transport = HttpTransport(
      client: client,
      apiKey: apiKey,
      baseUrl: baseUrl,
      retryHandler: retryHandler,
    );

    return AnthropicClient._(transport: transport, timeout: timeout);
  }

  /// Creates an [AnthropicClient] by reading the API key from the
  /// `ANTHROPIC_API_KEY` environment variable.
  ///
  /// Throws [AuthenticationException] if the environment variable is
  /// not set or is empty.
  ///
  /// Optional parameters are the same as the default constructor.
  factory AnthropicClient.fromEnvironment({
    String baseUrl = 'https://api.anthropic.com',
    Duration timeout = const Duration(seconds: 120),
    RetryPolicy? retryPolicy,
    http.Client? httpClient,
  }) {
    final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw const AuthenticationException(
        message:
            'ANTHROPIC_API_KEY environment variable is not set. '
            'Please set it to your Anthropic API key.',
      );
    }

    return AnthropicClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
      timeout: timeout,
      retryPolicy: retryPolicy,
      httpClient: httpClient,
    );
  }

  /// Provides access to the Anthropic Messages API.
  ///
  /// Throws [ClientClosedException] if the client has been closed.
  MessagesApi get messages {
    _ensureNotClosed();
    return _messagesApi;
  }

  /// Releases all HTTP resources held by this client.
  ///
  /// After calling this method, any attempt to use the client (e.g.
  /// accessing [messages]) will throw [ClientClosedException].
  ///
  /// It is safe to call [close] multiple times.
  void close() {
    if (!_closed) {
      _closed = true;
      _transport.close();
    }
  }

  /// Throws [ClientClosedException] if the client has been closed.
  void _ensureNotClosed() {
    if (_closed) {
      throw const ClientClosedException(
        message: 'Client has been closed. Create a new AnthropicClient '
            'instance to continue making requests.',
      );
    }
  }
}
