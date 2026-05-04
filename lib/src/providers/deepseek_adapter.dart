import '../client/feature.dart';
import '../client/provider.dart';
import 'provider_adapter.dart';

class DeepSeekAdapter extends ProviderAdapter {
  @override
  Provider get provider => Provider.deepseek;

  @override
  String get baseUrl => 'https://api.deepseek.com';

  @override
  Set<Feature> get supportedFeatures => {
    Feature.toolUse, Feature.streaming, Feature.systemPrompt,
  };

  @override
  Map<String, String> buildHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'content-type': 'application/json',
  };

  @override
  Uri buildUri(String path) => Uri.parse('$baseUrl$path');
}
