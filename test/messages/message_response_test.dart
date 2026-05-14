import 'package:claudio_sdk/src/messages/message_response.dart';
import 'package:test/test.dart';

void main() {
  group('Usage', () {
    test('fromJson', () {
      final usage = Usage.fromJson({'input_tokens': 10, 'output_tokens': 20});
      expect(usage.inputTokens, 10);
      expect(usage.outputTokens, 20);
    });
  });

  group('Message', () {
    test('fromJson with text content', () {
      final json = {
        'id': 'msg_123',
        'model': 'claude-sonnet-4-20250514',
        'stop_reason': 'end_turn',
        'usage': {'input_tokens': 10, 'output_tokens': 20},
        'content': [{'type': 'text', 'text': 'Hello!'}],
      };
      final msg = Message.fromJson(json);
      expect(msg.id, 'msg_123');
      expect(msg.stopReason, 'end_turn');
      expect(msg.text, 'Hello!');
      expect(msg.hasToolUse, false);
      expect(msg.toolUseBlocks, isEmpty);
    });

    test('fromJson with tool_use', () {
      final json = {
        'id': 'msg_456',
        'model': 'claude-sonnet-4-20250514',
        'stop_reason': 'tool_use',
        'usage': {'input_tokens': 5, 'output_tokens': 15},
        'content': [
          {'type': 'tool_use', 'id': 'toolu_01', 'name': 'get_weather', 'input': {'city': 'Tokyo'}},
        ],
      };
      final msg = Message.fromJson(json);
      expect(msg.hasToolUse, true);
      expect(msg.toolUseBlocks, hasLength(1));
      expect(msg.toolUseBlocks.first.name, 'get_weather');
    });

    test('text getter concatenates multiple TextBlocks', () {
      final json = {
        'id': 'msg', 'model': 'test', 'stop_reason': 'end_turn',
        'usage': {'input_tokens': 1, 'output_tokens': 2},
        'content': [
          {'type': 'text', 'text': 'Hello'},
          {'type': 'text', 'text': 'World'},
        ],
      };
      expect(Message.fromJson(json).text, 'Hello\nWorld');
    });

    test('toAssistantParam', () {
      final json = {
        'id': 'msg', 'model': 'test', 'stop_reason': 'end_turn',
        'usage': {'input_tokens': 1, 'output_tokens': 1},
        'content': [{'type': 'text', 'text': 'Hi'}],
      };
      final param = Message.fromJson(json).toAssistantParam();
      expect(param.role, 'assistant');
    });
  });
}
