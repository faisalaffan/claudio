import '../client/feature.dart';
import '../client/provider.dart';
import 'claudio_exception.dart';

class UnsupportedFeatureException extends ClaudioException {
  final Feature feature;
  final Provider provider;

  UnsupportedFeatureException({
    required this.feature,
    required this.provider,
  }) : super('Feature $feature is not supported by provider $provider');
}
