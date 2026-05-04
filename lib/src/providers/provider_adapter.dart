import '../client/feature.dart';
import '../client/provider.dart';
import '../messages/create_request.dart';
import '../errors/unsupported_feature_exception.dart';

/// Abstract adapter that each provider must implement.
abstract class ProviderAdapter {
  Provider get provider;
  String get baseUrl;
  Set<Feature> get supportedFeatures;

  Map<String, String> buildHeaders(String apiKey);
  Uri buildUri(String path);

  void validateRequest(CreateMessageRequest request) {
    if (request.thinking != null &&
        request.thinking!.type == 'enabled' &&
        !supportedFeatures.contains(Feature.extendedThinking)) {
      throw UnsupportedFeatureException(
        feature: Feature.extendedThinking,
        provider: provider,
      );
    }
  }
}
