import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:anthropic_sdk_dart/src/serialization/serializer.dart';
import 'package:test/test.dart';

void main() {
  late Serializer serializer;

  setUp(() {
    serializer = const Serializer();
  });

  group('Serializer', () {
    group('serializeRequest', () {
      test('serializes minimal request with snake_case field names', () {
        final request = CreateMessageRequest(
          model: 'claude-sonnet-4-20250514',
          maxTokens: 1024,
          messages: [
            MessageParam(role: 'user', content: 'Hello!'),
          ],
        );

        final json = serializer.serializeRequest(request);

        expect(json['model'], 'claude-sonnet-4-20250514');
        expect(json['max_tokens'], 1024);
        expect(json['stream'], false);
        expect(json['messages'], isList);
        expect((json['messages'] as List).length, 1);
        // Optional fields should not be present
        expect(json.containsKey('system'), false);
        expect(json.containsKey('tools'), false);
        expect(json.containsKey('tool_choice'), false);
        expect(json.containsKey('thinking'), false);
        expect(json.containsKey('stop_sequences'), false);
        expect(json.containsKey('temperature'), false);
        expect(json.containsKey('top_p'), false);
        expect(json.containsKey('top_k'), false);
      });

      test('serializes request with all optional fields', () {
        final request = CreateMessageRequest(
          model: 'claude-sonnet-4-20250514',
          maxTokens: 2048,
          messages: [
            MessageParam(role: 'user', content: 'Use the tool'),
          ],
          systemPrompt: 'You are helpful.',
          tools: [
            Tool(
              name: 'get_weather',
              description: 'Get weather',
              inputSchema: {
                'type': 'object',
                'properties': {
                  'city': {'type': 'string'},
                },
              },
            ),
          ],
          toolChoice: const ToolChoice.auto(),
          thinking: ThinkingConfig.enabled(budgetTokens: 4096),
          stopSequences: ['STOP'],
          temperature: 0.7,
          topP: 0.9,
          topK: 40,
        );

        final json = serializer.serializeRequest(request);

        expect(json['system'], 'You are helpful.');
        expect(json['tools'], isList);
        expect(json['tool_choice'], {'type': 'auto'});
        expect(json['thinking'], {
          'type': 'enabled',
          'budget_tokens': 4096,
        });
        expect(json['stop_sequences'], ['STOP']);
        expect(json['temperature'], 0.7);
        expect(json['top_p'], 0.9);
        expect(json['top_k'], 40);
      });

      test('produces same output as request.toJson()', () {
        final request = CreateMessageRequest(
          model: 'claude-sonnet-4-20250514',
          maxTokens: 512,
          messages: [
            MessageParam(role: 'user', content: 'Test'),
          ],
          temperature: 0.5,
        );

        expect(serializer.serializeRequest(request), request.toJson());
      });
    });

    group('serializeMessage', () {
      test('serializes message with string content', () {
        final message = MessageParam(role: 'user', content: 'Hello!');
        final json = serializer.serializeMessage(message);

        expect(json['role'], 'user');
        expect(json['content'], 'Hello!');
      });

      test('serializes message with content block list', () {
        final message = MessageParam(
          role: 'user',
          content: [
            const TextBlock(text: 'Look at this image'),
            const ImageBlock(
              source: ImageSource(
                type: 'base64',
                mediaType: 'image/png',
                data: 'iVBOR...',
              ),
            ),
          ],
        );
        final json = serializer.serializeMessage(message);

        expect(json['role'], 'user');
        final content = json['content'] as List;
        expect(content.length, 2);
        expect((content[0] as Map<String, dynamic>)['type'], 'text');
        expect((content[1] as Map<String, dynamic>)['type'], 'image');
      });

      test('produces same output as message.toJson()', () {
        final message = MessageParam(role: 'assistant', content: 'Hi');
        expect(serializer.serializeMessage(message), message.toJson());
      });
    });

    group('serializeTool', () {
      test('serializes tool with snake_case input_schema', () {
        final tool = Tool(
          name: 'get_weather',
          description: 'Get weather for a city',
          inputSchema: SchemaBuilder()
              .object(
                properties: {
                  'city': SchemaProperty.string(description: 'City name'),
                },
                required: ['city'],
              )
              .build(),
        );

        final json = serializer.serializeTool(tool);

        expect(json['name'], 'get_weather');
        expect(json['description'], 'Get weather for a city');
        expect(json.containsKey('input_schema'), true);
        expect(json.containsKey('inputSchema'), false);
      });

      test('produces same output as tool.toJson()', () {
        final tool = Tool(
          name: 'calc',
          description: 'Calculate',
          inputSchema: {'type': 'object', 'properties': <String, dynamic>{}},
        );
        expect(serializer.serializeTool(tool), tool.toJson());
      });
    });

    group('serializeContentBlock', () {
      test('serializes TextBlock', () {
        const block = TextBlock(text: 'Hello');
        final json = serializer.serializeContentBlock(block);

        expect(json['type'], 'text');
        expect(json['text'], 'Hello');
      });

      test('serializes ToolUseBlock', () {
        const block = ToolUseBlock(
          id: 'toolu_123',
          name: 'get_weather',
          input: {'city': 'Paris'},
        );
        final json = serializer.serializeContentBlock(block);

        expect(json['type'], 'tool_use');
        expect(json['id'], 'toolu_123');
        expect(json['name'], 'get_weather');
        expect(json['input'], {'city': 'Paris'});
      });

      test('serializes ToolResultBlock with snake_case tool_use_id', () {
        const block = ToolResultBlock(
          toolUseId: 'toolu_123',
          content: [TextBlock(text: '25°C')],
        );
        final json = serializer.serializeContentBlock(block);

        expect(json['type'], 'tool_result');
        expect(json['tool_use_id'], 'toolu_123');
        expect(json.containsKey('toolUseId'), false);
        expect(json.containsKey('is_error'), false);
      });

      test('serializes ToolResultBlock with is_error flag', () {
        const block = ToolResultBlock(
          toolUseId: 'toolu_456',
          content: [TextBlock(text: 'Error occurred')],
          isError: true,
        );
        final json = serializer.serializeContentBlock(block);

        expect(json['is_error'], true);
      });

      test('serializes ImageBlock with snake_case media_type', () {
        const block = ImageBlock(
          source: ImageSource(
            type: 'base64',
            mediaType: 'image/png',
            data: 'iVBOR...',
          ),
        );
        final json = serializer.serializeContentBlock(block);

        expect(json['type'], 'image');
        final source = json['source'] as Map<String, dynamic>;
        expect(source['media_type'], 'image/png');
        expect(source.containsKey('mediaType'), false);
      });

      test('serializes ThinkingBlock', () {
        const block = ThinkingBlock(
          thinking: 'Let me think...',
          signature: 'sig123',
        );
        final json = serializer.serializeContentBlock(block);

        expect(json['type'], 'thinking');
        expect(json['thinking'], 'Let me think...');
        expect(json['signature'], 'sig123');
      });

      test('serializes RedactedThinkingBlock', () {
        const block = RedactedThinkingBlock(data: 'opaque-data');
        final json = serializer.serializeContentBlock(block);

        expect(json['type'], 'redacted_thinking');
        expect(json['data'], 'opaque-data');
      });

      test('produces same output as block.toJson()', () {
        const block = TextBlock(text: 'test');
        expect(serializer.serializeContentBlock(block), block.toJson());
      });
    });
  });
}
