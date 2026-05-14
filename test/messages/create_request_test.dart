import 'package:claudio_sdk/src/messages/create_request.dart';
import 'package:claudio_sdk/src/messages/message_param.dart';
import 'package:claudio_sdk/src/tools/tool.dart';
import 'package:claudio_sdk/src/tools/tool_choice.dart';
import 'package:test/test.dart';

void main() {
  group('ThinkingConfig', () {
    test('enabled with default budget', () {
      final config = ThinkingConfig.enabled();
      expect(config.type, 'enabled');
      expect(config.budgetTokens, 1024);
    });

    test('disabled', () {
      final config = ThinkingConfig.disabled();
      expect(config.type, 'disabled');
      expect(config.budgetTokens, isNull);
    });

    test('auto', () {
      expect(ThinkingConfig.auto().type, 'auto');
    });

    test('toJson excludes null budgetTokens', () {
      expect(ThinkingConfig.disabled().toJson(), {'type': 'disabled'});
    });
  });

  group('CreateMessageRequest', () {
    test('minimal toJson', () {
      final request = CreateMessageRequest(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1024,
        messages: [MessageParam(role: 'user', content: 'Hi')],
      );
      final json = request.toJson();
      expect(json['model'], 'claude-sonnet-4-20250514');
      expect(json['max_tokens'], 1024);
      expect(json['stream'], false);
    });

    test('with system prompt', () {
      final request = CreateMessageRequest(
        model: 'test', maxTokens: 100, messages: [],
        systemPrompt: 'Be helpful.',
      );
      expect(request.toJson()['system'], 'Be helpful.');
    });

    test('with tools and toolChoice', () {
      final request = CreateMessageRequest(
        model: 'test', maxTokens: 100, messages: [],
        tools: [Tool(name: 'my_tool', inputSchema: {})],
        toolChoice: const ToolChoiceAuto(),
      );
      final json = request.toJson();
      expect(json['tools'], isA<List>()); // ignore: strict_raw_type
      expect(json['tool_choice'], {'type': 'auto'});
    });

    test('toStreamJson sets stream to true', () {
      final request = CreateMessageRequest(model: 'test', maxTokens: 100, messages: []);
      expect(request.toStreamJson()['stream'], true);
      expect(request.toJson()['stream'], false);
    });
  });
}
