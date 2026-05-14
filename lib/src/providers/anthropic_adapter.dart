import '../client/feature.dart';
import '../client/provider.dart';
import 'provider_adapter.dart';

/// Provider adapter for the Anthropic API.
class AnthropicAdapter extends ProviderAdapter {
  @override
  Provider get provider => Provider.anthropic;

  @override
  String get baseUrl => 'https://api.anthropic.com';

  @override
  Set<Feature> get supportedFeatures => {
    Feature.extendedThinking, Feature.imageInput, Feature.toolUse,
    Feature.streaming, Feature.systemPrompt, Feature.promptCaching,
  };

  @override
  Map<String, String> buildHeaders(String apiKey) => {
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  };

  @override
  Uri buildUri(String path) => Uri.parse('$baseUrl$path');
}
