import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:test/test.dart';

void main() {
  group('StopReason', () {
    test('fromString parses all valid values', () {
      expect(StopReason.fromString('end_turn'), StopReason.endTurn);
      expect(StopReason.fromString('max_tokens'), StopReason.maxTokens);
      expect(StopReason.fromString('stop_sequence'), StopReason.stopSequence);
      expect(StopReason.fromString('tool_use'), StopReason.toolUse);
    });

    test('fromString throws on unknown value', () {
      expect(() => StopReason.fromString('unknown'), throwsArgumentError);
    });

    test('toJson returns snake_case values', () {
      expect(StopReason.endTurn.toJson(), 'end_turn');
      expect(StopReason.maxTokens.toJson(), 'max_tokens');
      expect(StopReason.stopSequence.toJson(), 'stop_sequence');
      expect(StopReason.toolUse.toJson(), 'tool_use');
    });

    test('round-trip fromString/toJson', () {
      for (final reason in StopReason.values) {
        expect(StopReason.fromString(reason.toJson()), reason);
      }
    });
  });

  group('Message', () {
    final sampleJson = <String, dynamic>{
      'id': 'msg_01XFDUDYJgAACzvnptvVoYEL',
      'type': 'message',
      'role': 'assistant',
      'content': [
        {'type': 'text', 'text': 'Hello!'},
      ],
      'model': 'claude-sonnet-4-20250514',
      'stop_reason': 'end_turn',
      'usage': {'input_tokens': 25, 'output_tokens': 15},
    };

    test('fromJson creates correct Message', () {
      final message = Message.fromJson(sampleJson);

      expect(message.id, 'msg_01XFDUDYJgAACzvnptvVoYEL');
      expect(message.role, 'assistant');
      expect(message.model, 'claude-sonnet-4-20250514');
      expect(message.stopReason, StopReason.endTurn);
      expect(message.usage.inputTokens, 25);
      expect(message.usage.outputTokens, 15);
      expect(message.content, hasLength(1));
      expect(message.content.first, isA<TextBlock>());
    });

    test('toJson produces correct JSON', () {
      final message = Message.fromJson(sampleJson);
      final json = message.toJson();

      expect(json['id'], 'msg_01XFDUDYJgAACzvnptvVoYEL');
      expect(json['type'], 'message');
      expect(json['role'], 'assistant');
      expect(json['model'], 'claude-sonnet-4-20250514');
      expect(json['stop_reason'], 'end_turn');
      expect(json['usage'], {'input_tokens': 25, 'output_tokens': 15});
      expect(json['content'], hasLength(1));
    });

    test('text getter joins TextBlock texts with newlines', () {
      final message = Message(
        id: 'msg_1',
        role: 'assistant',
        content: [
          const TextBlock(text: 'Hello'),
          const ToolUseBlock(
            id: 'tool_1',
            name: 'get_weather',
            input: {'city': 'NYC'},
          ),
          const TextBlock(text: 'World'),
        ],
        model: 'claude-sonnet-4-20250514',
        stopReason: StopReason.endTurn,
        usage: const Usage(inputTokens: 10, outputTokens: 5),
      );

      expect(message.text, 'Hello\nWorld');
    });

    test('text getter returns empty string when no TextBlocks', () {
      final message = Message(
        id: 'msg_1',
        role: 'assistant',
        content: [
          const ToolUseBlock(
            id: 'tool_1',
            name: 'get_weather',
            input: {'city': 'NYC'},
          ),
        ],
        model: 'claude-sonnet-4-20250514',
        stopReason: StopReason.toolUse,
        usage: const Usage(inputTokens: 10, outputTokens: 5),
      );

      expect(message.text, '');
    });

    test('toolUseBlocks extracts only ToolUseBlocks', () {
      final toolBlock1 = const ToolUseBlock(
        id: 'tool_1',
        name: 'get_weather',
        input: {'city': 'NYC'},
      );
      final toolBlock2 = const ToolUseBlock(
        id: 'tool_2',
        name: 'get_time',
        input: {'zone': 'UTC'},
      );

      final message = Message(
        id: 'msg_1',
        role: 'assistant',
        content: [
          const TextBlock(text: 'Let me help'),
          toolBlock1,
          const TextBlock(text: 'Also checking'),
          toolBlock2,
        ],
        model: 'claude-sonnet-4-20250514',
        stopReason: StopReason.toolUse,
        usage: const Usage(inputTokens: 10, outputTokens: 5),
      );

      final blocks = message.toolUseBlocks;
      expect(blocks, hasLength(2));
      expect(blocks[0], toolBlock1);
      expect(blocks[1], toolBlock2);
    });

    test('toolUseBlocks returns empty list when none present', () {
      final message = Message(
        id: 'msg_1',
        role: 'assistant',
        content: [const TextBlock(text: 'Hello')],
        model: 'claude-sonnet-4-20250514',
        stopReason: StopReason.endTurn,
        usage: const Usage(inputTokens: 10, outputTokens: 5),
      );

      expect(message.toolUseBlocks, isEmpty);
    });

    test('equality works correctly', () {
      final msg1 = Message.fromJson(sampleJson);
      final msg2 = Message.fromJson(sampleJson);
      expect(msg1, equals(msg2));
      expect(msg1.hashCode, msg2.hashCode);
    });

    test('fromJson handles mixed content blocks', () {
      final json = <String, dynamic>{
        'id': 'msg_2',
        'type': 'message',
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': 'I will use a tool'},
          {
            'type': 'tool_use',
            'id': 'toolu_01',
            'name': 'calculator',
            'input': {'expression': '2+2'},
          },
        ],
        'model': 'claude-sonnet-4-20250514',
        'stop_reason': 'tool_use',
        'usage': {'input_tokens': 30, 'output_tokens': 20},
      };

      final message = Message.fromJson(json);
      expect(message.content, hasLength(2));
      expect(message.content[0], isA<TextBlock>());
      expect(message.content[1], isA<ToolUseBlock>());
      expect(message.stopReason, StopReason.toolUse);
    });
  });

  group('MessageParam', () {
    test('creates with string content', () {
      final param = MessageParam(role: 'user', content: 'Hello!');
      expect(param.role, 'user');
      expect(param.content, 'Hello!');
    });

    test('creates with List<ContentBlock> content', () {
      final blocks = <ContentBlock>[const TextBlock(text: 'Hello!')];
      final param = MessageParam(role: 'user', content: blocks);
      expect(param.role, 'user');
      expect(param.content, blocks);
    });

    test('throws ArgumentError for invalid content type', () {
      expect(
        () => MessageParam(role: 'user', content: 42),
        throwsArgumentError,
      );
    });

    test('toJson with string content', () {
      final param = MessageParam(role: 'user', content: 'Hello!');
      final json = param.toJson();
      expect(json, {'role': 'user', 'content': 'Hello!'});
    });

    test('toJson with List<ContentBlock> content', () {
      final param = MessageParam(
        role: 'user',
        content: <ContentBlock>[const TextBlock(text: 'Hello!')],
      );
      final json = param.toJson();
      expect(json['role'], 'user');
      expect(json['content'], [
        {'type': 'text', 'text': 'Hello!'},
      ]);
    });

    test('fromJson with string content', () {
      final param = MessageParam.fromJson({
        'role': 'user',
        'content': 'Hello!',
      });
      expect(param.role, 'user');
      expect(param.content, 'Hello!');
    });

    test('fromJson with list content', () {
      final param = MessageParam.fromJson({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'Hello!'},
        ],
      });
      expect(param.role, 'user');
      expect(param.content, isA<List>());
      final blocks = param.content as List<ContentBlock>;
      expect(blocks, hasLength(1));
      expect(blocks.first, isA<TextBlock>());
    });

    test('equality with string content', () {
      final a = MessageParam(role: 'user', content: 'Hello');
      final b = MessageParam(role: 'user', content: 'Hello');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('equality with list content', () {
      final a = MessageParam(
        role: 'user',
        content: <ContentBlock>[const TextBlock(text: 'Hi')],
      );
      final b = MessageParam(
        role: 'user',
        content: <ContentBlock>[const TextBlock(text: 'Hi')],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
