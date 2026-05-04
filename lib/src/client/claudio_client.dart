import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'provider.dart';
import 'retry_policy.dart';
import '../errors/client_closed_exception.dart';
import '../http/http_client.dart';
import '../messages/messages_api.dart';
import '../providers/anthropic_adapter.dart';
import '../providers/deepseek_adapter.dart';
import '../providers/provider_adapter.dart';

/// Main entry point for the claudio SDK.
class ClaudioClient {
  final String _apiKey;
  final Provider _provider;
  final Duration _timeout;
  final RetryPolicy _retryPolicy;
  late final ProviderAdapter _adapter;
  late final ClaudioHttpClient _httpClient;
  late final MessagesApi _messages;
  bool _closed = false;

  ClaudioClient({
    required String apiKey,
    required Provider provider,
    Duration timeout = const Duration(seconds: 120),
    RetryPolicy retryPolicy = const RetryPolicy(),
  })  : _apiKey = apiKey,
        _provider = provider,
        _timeout = timeout,
        _retryPolicy = retryPolicy {
    _adapter = _createAdapter(provider);
    _httpClient = ClaudioHttpClient(
      inner: http.Client(),
      retryPolicy: _retryPolicy,
      timeout: _timeout,
    );
    _messages = MessagesApi(
      httpClient: _httpClient,
      adapter: _adapter,
      apiKey: _apiKey,
    );
  }

  factory ClaudioClient.fromEnvironment() {
    final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ??
        Platform.environment['DEEPSEEK_API_KEY'] ??
        Platform.environment['API_KEY'] ??
        '';
    if (apiKey.isEmpty) {
      throw ArgumentError(
        'No API key found. Set ANTHROPIC_API_KEY, DEEPSEEK_API_KEY, or API_KEY.',
      );
    }

    final providerStr = Platform.environment['CLOUD_PROVIDER'] ?? 'anthropic';
    final provider = Provider.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => Provider.anthropic,
    );

    return ClaudioClient(apiKey: apiKey, provider: provider);
  }

  ProviderAdapter _createAdapter(Provider provider) {
    return switch (provider) {
      Provider.anthropic => AnthropicAdapter(),
      Provider.deepseek => DeepSeekAdapter(),
    };
  }

  MessagesApi get messages {
    _checkClosed();
    return _messages;
  }

  Provider get provider => _provider;

  void close() {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }

  void _checkClosed() {
    if (_closed) throw const ClientClosedException();
  }
}
