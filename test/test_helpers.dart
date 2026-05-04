import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:claudio/src/providers/provider_adapter.dart';

@GenerateNiceMocks([
  MockSpec<http.Client>(),
  MockSpec<ProviderAdapter>(),
])
void main() {}
