import 'package:claudio/src/client/feature.dart';
import 'package:claudio/src/client/provider.dart';
import 'package:claudio/src/errors/claudio_exception.dart';
import 'package:claudio/src/errors/authentication_exception.dart';
import 'package:claudio/src/errors/rate_limit_exception.dart';
import 'package:claudio/src/errors/invalid_request_exception.dart';
import 'package:claudio/src/errors/api_exception.dart';
import 'package:claudio/src/errors/network_exception.dart';
import 'package:claudio/src/errors/stream_exception.dart';
import 'package:claudio/src/errors/unsupported_feature_exception.dart';
import 'package:claudio/src/errors/client_closed_exception.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudioException', () {
    test('AuthenticationException', () {
      final e = AuthenticationException('Invalid key', statusCode: 401);
      expect(e.statusCode, 401);
      expect(e.message, 'Invalid key');
      expect(e, isA<ClaudioException>());
    });

    test('RateLimitException with retryAfter', () {
      final e = RateLimitException('Too many', retryAfter: Duration(seconds: 30));
      expect(e.retryAfter, const Duration(seconds: 30));
    });

    test('InvalidRequestException', () {
      final e = InvalidRequestException('Bad input', statusCode: 400);
      expect(e.statusCode, 400);
      expect(e, isA<ClaudioException>());
    });

    test('ApiException', () {
      final e = ApiException('Server error', statusCode: 500);
      expect(e.statusCode, 500);
      expect(e, isA<ClaudioException>());
    });

    test('NetworkException', () {
      final e = NetworkException('Connection refused');
      expect(e.message, 'Connection refused');
      expect(e, isA<ClaudioException>());
    });

    test('StreamException', () {
      final e = StreamException('SSE connection lost');
      expect(e.message, 'SSE connection lost');
      expect(e, isA<ClaudioException>());
    });

    test('UnsupportedFeatureException', () {
      final e = UnsupportedFeatureException(
        feature: Feature.extendedThinking,
        provider: Provider.deepseek,
      );
      expect(e.feature, Feature.extendedThinking);
      expect(e.provider, Provider.deepseek);
      expect(e.message, contains('extendedThinking'));
      expect(e.message, contains('deepseek'));
    });

    test('ClientClosedException', () {
      final e = ClientClosedException();
      expect(e.message, contains('closed'));
      expect(e, isA<ClaudioException>());
    });
  });
}
