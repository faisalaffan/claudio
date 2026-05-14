import 'package:claudio_sdk/claudio_sdk.dart';

void main() async {
  // Anthropic
  final anthropicClient = ClaudioClient(
    apiKey: 'sk-ant-your-api-key',
    provider: Provider.anthropic,
  );

  final message = await anthropicClient.messages.create(
    CreateMessageRequest(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1024,
      messages: [MessageParam(role: 'user', content: 'Hello, Claude!')],
    ),
  );
  print('Anthropic: ${message.text}');
  anthropicClient.close();

  // DeepSeek
  final deepSeekClient = ClaudioClient(
    apiKey: 'sk-deepseek-your-api-key',
    provider: Provider.deepseek,
  );

  final dsMessage = await deepSeekClient.messages.create(
    CreateMessageRequest(
      model: 'deepseek-chat',
      maxTokens: 1024,
      messages: [MessageParam(role: 'user', content: 'Hello!')],
    ),
  );
  print('DeepSeek: ${dsMessage.text}');
  deepSeekClient.close();
}
