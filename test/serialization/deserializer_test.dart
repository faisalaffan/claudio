import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:anthropic_sdk_dart/src/serialization/deserializer.dart';
import 'package:test/test.dart';

void main() {
  late Deserializer deserializer;

  setUp(() {
    deserializer = const Deserializer();
  });

  group('Deserializer', () {
    group('deserializeMessage', () {
      test('deserializes a minimal API response message', () {
        final json = <String, dynamic>{
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

        final message = deserializer.deserializeMessage(json);

        expect(message.id, 'msg_01XFDUDYJgAACzvnptvVoYEL');
        expect(message.role, 'assistant');
        expect(message.model, 'claude-sonnet-4-20250514');
        expect(message.stopReason, StopReason.endTurn);
        expect(message.usage.inputTokens, 25);
        expect(message.usage.outputTokens, 15);
        expect(message.content.length, 1);
        expect(message.content[0], isA<TextBlock>());
        expect((message.content[0] as TextBlock).text, 'Hello!');
      });

      test('deserializes message with tool_use stop reason', () {
        final json = <String, dynamic>{
          'id': 'msg_abc',
          'type': 'message',
          'role': 'assistant',
          'content': [
            {
              'type': 'tool_use',
              'id': 'toolu_123',
              'name': 'get_weather',
              'input': {'city': 'Paris'},
            },
          ],
          'model': 'claude-sonnet-4-20250514',
          'stop_reason': 'tool_use',
          'usage': {'input_tokens': 50, 'output_tokens': 30},
        };

        final message = deserializer.deserializeMessage(json);

        expect(message.stopReason, StopReason.toolUse);
        expect(message.content.length, 1);
        final block = message.content[0] as ToolUseBlock;
        expect(block.id, 'toolu_123');
        expect(block.name, 'get_weather');
        expect(block.input, {'city': 'Paris'});
      });

      test('deserializes message with mixed content blocks', () {
        final json = <String, dynamic>{
          'id': 'msg_mixed',
          'type': 'message',
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': 'Let me check the weather.'},
            {
              'type': 'tool_use',
              'id': 'toolu_456',
              'name': 'get_weather',
              'input': {'location': 'Tokyo'},
            },
          ],
          'model': 'claude-sonnet-4-20250514',
          'stop_reason': 'tool_use',
          'usage': {'input_tokens': 100, 'output_tokens': 50},
        };

        final message = deserializer.deserializeMessage(json);

        expect(message.content.length, 2);
        expect(message.content[0], isA<TextBlock>());
        expect(message.content[1], isA<ToolUseBlock>());
      });

      test('deserializes message with thinking blocks', () {
        final json = <String, dynamic>{
          'id': 'msg_think',
          'type': 'message',
          'role': 'assistant',
          'content': [
            {
              'type': 'thinking',
              'thinking': 'Let me reason step by step...',
              'signature': 'sig_abc',
            },
            {'type': 'text', 'text': 'The answer is 42.'},
          ],
          'model': 'claude-sonnet-4-20250514',
          'stop_reason': 'end_turn',
          'usage': {'input_tokens': 30, 'output_tokens': 200},
        };

        final message = deserializer.deserializeMessage(json);

        expect(message.content.length, 2);
        final thinking = message.content[0] as ThinkingBlock;
        expect(thinking.thinking, 'Let me reason step by step...');
        expect(thinking.signature, 'sig_abc');
        expect(message.content[1], isA<TextBlock>());
      });

      test('ignores unknown fields in JSON (forward compatibility)', () {
        final json = <String, dynamic>{
          'id': 'msg_compat',
          'type': 'message',
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': 'Hi'},
          ],
          'model': 'claude-sonnet-4-20250514',
          'stop_reason': 'end_turn',
          'usage': {'input_tokens': 10, 'output_tokens': 5},
          // Unknown fields — should be silently ignored
          'new_future_field': 'some_value',
          'another_unknown': 42,
          'nested_unknown': {'key': 'value'},
        };

        final message = deserializer.deserializeMessage(json);

        expect(message.id, 'msg_compat');
        expect(message.content.length, 1);
        expect((message.content[0] as TextBlock).text, 'Hi');
      });

      test('uses default role when role is missing', () {
        final json = <String, dynamic>{
          'id': 'msg_norole',
          'type': 'message',
          'content': [
            {'type': 'text', 'text': 'Hello'},
          ],
          'model': 'claude-sonnet-4-20250514',
          'stop_reason': 'end_turn',
          'usage': {'input_tokens': 5, 'output_tokens': 3},
        };

        final message = deserializer.deserializeMessage(json);

        expect(message.role, 'assistant');
      });
    });

    group('deserializeContentBlock', () {
      test('delegates to ContentBlockParser for text block', () {
        final json = <String, dynamic>{'type': 'text', 'text': 'Hello!'};
        final block = deserializer.deserializeContentBlock(json);

        expect(block, isA<TextBlock>());
        expect((block as TextBlock).text, 'Hello!');
      });

      test('delegates to ContentBlockParser for tool_use block', () {
        final json = <String, dynamic>{
          'type': 'tool_use',
          'id': 'toolu_789',
          'name': 'calculator',
          'input': {'expression': '2+2'},
        };
        final block = deserializer.deserializeContentBlock(json);

        expect(block, isA<ToolUseBlock>());
        final toolUse = block as ToolUseBlock;
        expect(toolUse.id, 'toolu_789');
        expect(toolUse.name, 'calculator');
      });

      test('handles unknown block type gracefully', () {
        final json = <String, dynamic>{
          'type': 'future_block_type',
          'data': 'something',
        };
        final block = deserializer.deserializeContentBlock(json);

        expect(block, isA<TextBlock>());
        expect(
          (block as TextBlock).text,
          contains('unknown block type'),
        );
      });
    });

    group('deserializeUsage', () {
      test('deserializes usage with snake_case fields', () {
        final json = <String, dynamic>{
          'input_tokens': 100,
          'output_tokens': 50,
        };

        final usage = deserializer.deserializeUsage(json);

        expect(usage.inputTokens, 100);
        expect(usage.outputTokens, 50);
      });

      test('uses default 0 for missing fields', () {
        final json = <String, dynamic>{};

        final usage = deserializer.deserializeUsage(json);

        expect(usage.inputTokens, 0);
        expect(usage.outputTokens, 0);
      });

      test('ignores unknown fields in usage JSON', () {
        final json = <String, dynamic>{
          'input_tokens': 10,
          'output_tokens': 5,
          'cache_creation_input_tokens': 100,
          'cache_read_input_tokens': 50,
        };

        final usage = deserializer.deserializeUsage(json);

        expect(usage.inputTokens, 10);
        expect(usage.outputTokens, 5);
      });
    });

    group('deserializeTool', () {
      test('deserializes tool with snake_case input_schema', () {
        final json = <String, dynamic>{
          'name': 'get_weather',
          'description': 'Get the weather for a location',
          'input_schema': {
            'type': 'object',
            'properties': {
              'location': {'type': 'string', 'description': 'City name'},
            },
            'required': ['location'],
          },
        };

        final tool = deserializer.deserializeTool(json);

        expect(tool.name, 'get_weather');
        expect(tool.description, 'Get the weather for a location');
        expect(tool.inputSchema['type'], 'object');
        expect(
          (tool.inputSchema['properties']
              as Map<String, dynamic>)['location'],
          isA<Map<String, dynamic>>(),
        );
      });

      test('uses empty string default for missing description', () {
        final json = <String, dynamic>{
          'name': 'my_tool',
          'input_schema': {
            'type': 'object',
            'properties': <String, dynamic>{},
          },
        };

        final tool = deserializer.deserializeTool(json);

        expect(tool.name, 'my_tool');
        expect(tool.description, '');
      });

      test('ignores unknown fields in tool JSON', () {
        final json = <String, dynamic>{
          'name': 'search',
          'description': 'Search the web',
          'input_schema': {
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
            },
          },
          'cache_control': {'type': 'ephemeral'},
          'custom_field': 'ignored',
        };

        final tool = deserializer.deserializeTool(json);

        expect(tool.name, 'search');
        expect(tool.description, 'Search the web');
      });
    });

    group('round-trip: serialize then deserialize', () {
      test('Message round-trip preserves data', () {
        const original = Message(
          id: 'msg_roundtrip',
          role: 'assistant',
          content: [
            TextBlock(text: 'Hello world'),
            ToolUseBlock(
              id: 'toolu_rt',
              name: 'test_tool',
              input: {'key': 'value'},
            ),
          ],
          model: 'claude-sonnet-4-20250514',
          stopReason: StopReason.toolUse,
          usage: Usage(inputTokens: 10, outputTokens: 20),
        );

        final json = original.toJson();
        final restored = deserializer.deserializeMessage(json);

        expect(restored, original);
      });

      test('Tool round-trip preserves data', () {
        const original = Tool(
          name: 'get_weather',
          description: 'Get weather info',
          inputSchema: {
            'type': 'object',
            'properties': {
              'city': {'type': 'string'},
            },
            'required': ['city'],
          },
        );

        final json = original.toJson();
        final restored = deserializer.deserializeTool(json);

        expect(restored, original);
      });

      test('Usage round-trip preserves data', () {
        const original = Usage(inputTokens: 42, outputTokens: 99);

        final json = original.toJson();
        final restored = deserializer.deserializeUsage(json);

        expect(restored, original);
      });
    });
  });
}
