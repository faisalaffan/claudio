import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MessageToolUseExtension', () {
    Message _makeMessage(List<ContentBlock> content) {
      return Message(
        id: 'msg_test',
        role: 'assistant',
        content: content,
        model: 'claude-sonnet-4-20250514',
        stopReason: StopReason.endTurn,
        usage: const Usage(inputTokens: 10, outputTokens: 5),
      );
    }

    group('hasToolUse', () {
      test('returns true when message contains a ToolUseBlock', () {
        final message = _makeMessage([
          const TextBlock(text: 'Let me check that.'),
          const ToolUseBlock(
            id: 'toolu_01',
            name: 'get_weather',
            input: {'location': 'SF'},
          ),
        ]);
        expect(message.hasToolUse, isTrue);
      });

      test('returns false when message has no ToolUseBlock', () {
        final message = _makeMessage([
          const TextBlock(text: 'Hello!'),
        ]);
        expect(message.hasToolUse, isFalse);
      });

      test('returns false for empty content', () {
        final message = _makeMessage([]);
        expect(message.hasToolUse, isFalse);
      });

      test('returns true with multiple ToolUseBlocks', () {
        final message = _makeMessage([
          const ToolUseBlock(
            id: 'toolu_01',
            name: 'get_weather',
            input: {'location': 'SF'},
          ),
          const ToolUseBlock(
            id: 'toolu_02',
            name: 'get_time',
            input: {'timezone': 'PST'},
          ),
        ]);
        expect(message.hasToolUse, isTrue);
      });
    });

    group('toAssistantParam', () {
      test('creates MessageParam with role assistant and same content', () {
        final content = <ContentBlock>[
          const TextBlock(text: 'I will check the weather.'),
          const ToolUseBlock(
            id: 'toolu_01',
            name: 'get_weather',
            input: {'location': 'SF'},
          ),
        ];
        final message = _makeMessage(content);
        final param = message.toAssistantParam();

        expect(param.role, equals('assistant'));
        final paramContent = param.content as List<ContentBlock>;
        expect(paramContent.length, equals(2));
        expect(paramContent[0], isA<TextBlock>());
        expect((paramContent[0] as TextBlock).text,
            equals('I will check the weather.'));
        expect(paramContent[1], isA<ToolUseBlock>());
        expect((paramContent[1] as ToolUseBlock).id, equals('toolu_01'));
      });

      test('returns unmodifiable content list', () {
        final message = _makeMessage([
          const TextBlock(text: 'Hello'),
        ]);
        final param = message.toAssistantParam();
        final paramContent = param.content as List<ContentBlock>;

        expect(
          () => paramContent.add(const TextBlock(text: 'extra')),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });
  });

  group('createToolResult', () {
    test('creates ToolResultBlock with text wrapped in TextBlock', () {
      final result = createToolResult(
        toolUseId: 'toolu_01',
        text: '15 degrees',
      );

      expect(result.toolUseId, equals('toolu_01'));
      expect(result.content.length, equals(1));
      expect(result.content[0], isA<TextBlock>());
      expect((result.content[0] as TextBlock).text, equals('15 degrees'));
      expect(result.isError, isFalse);
    });

    test('creates ToolResultBlock with explicit content blocks', () {
      final result = createToolResult(
        toolUseId: 'toolu_02',
        content: [
          const TextBlock(text: 'Temperature: 15°C'),
          const TextBlock(text: 'Humidity: 60%'),
        ],
      );

      expect(result.toolUseId, equals('toolu_02'));
      expect(result.content.length, equals(2));
      expect(result.isError, isFalse);
    });

    test('content takes precedence over text when both provided', () {
      final result = createToolResult(
        toolUseId: 'toolu_03',
        text: 'ignored',
        content: [const TextBlock(text: 'used')],
      );

      expect(result.content.length, equals(1));
      expect((result.content[0] as TextBlock).text, equals('used'));
    });

    test('creates empty content when neither text nor content provided', () {
      final result = createToolResult(toolUseId: 'toolu_04');

      expect(result.toolUseId, equals('toolu_04'));
      expect(result.content, isEmpty);
      expect(result.isError, isFalse);
    });

    test('sets isError flag correctly', () {
      final result = createToolResult(
        toolUseId: 'toolu_05',
        text: 'Location not found',
        isError: true,
      );

      expect(result.isError, isTrue);
      expect((result.content[0] as TextBlock).text,
          equals('Location not found'));
    });
  });

  group('createToolResultMessage', () {
    test('creates user message with single tool result', () {
      final result = createToolResult(
        toolUseId: 'toolu_01',
        text: '15 degrees',
      );
      final message = createToolResultMessage([result]);

      expect(message.role, equals('user'));
      final content = message.content as List<ContentBlock>;
      expect(content.length, equals(1));
      expect(content[0], isA<ToolResultBlock>());
      expect((content[0] as ToolResultBlock).toolUseId, equals('toolu_01'));
    });

    test('creates user message with multiple tool results', () {
      final results = [
        createToolResult(toolUseId: 'toolu_01', text: '15 degrees'),
        createToolResult(toolUseId: 'toolu_02', text: 'Sunny'),
        createToolResult(
          toolUseId: 'toolu_03',
          text: 'Error occurred',
          isError: true,
        ),
      ];
      final message = createToolResultMessage(results);

      expect(message.role, equals('user'));
      final content = message.content as List<ContentBlock>;
      expect(content.length, equals(3));

      expect((content[0] as ToolResultBlock).toolUseId, equals('toolu_01'));
      expect((content[1] as ToolResultBlock).toolUseId, equals('toolu_02'));
      expect((content[2] as ToolResultBlock).toolUseId, equals('toolu_03'));
      expect((content[2] as ToolResultBlock).isError, isTrue);
    });

    test('creates user message with empty results list', () {
      final message = createToolResultMessage([]);

      expect(message.role, equals('user'));
      final content = message.content as List<ContentBlock>;
      expect(content, isEmpty);
    });
  });

  group('full tool use conversation flow', () {
    test('builds a complete multi-turn tool use conversation', () {
      // 1. Initial user message
      final userMessage = MessageParam(
        role: 'user',
        content: 'What is the weather in SF and NYC?',
      );

      // 2. Simulate assistant response with tool use
      final assistantResponse = Message(
        id: 'msg_01',
        role: 'assistant',
        content: [
          const TextBlock(text: 'Let me check both locations.'),
          const ToolUseBlock(
            id: 'toolu_01',
            name: 'get_weather',
            input: {'location': 'San Francisco'},
          ),
          const ToolUseBlock(
            id: 'toolu_02',
            name: 'get_weather',
            input: {'location': 'New York'},
          ),
        ],
        model: 'claude-sonnet-4-20250514',
        stopReason: StopReason.toolUse,
        usage: const Usage(inputTokens: 50, outputTokens: 30),
      );

      // 3. Check for tool use
      expect(assistantResponse.hasToolUse, isTrue);
      expect(assistantResponse.toolUseBlocks.length, equals(2));

      // 4. Convert assistant response to param
      final assistantParam = assistantResponse.toAssistantParam();
      expect(assistantParam.role, equals('assistant'));

      // 5. Create tool results
      final toolResults = createToolResultMessage([
        createToolResult(toolUseId: 'toolu_01', text: '65°F, Foggy'),
        createToolResult(toolUseId: 'toolu_02', text: '72°F, Sunny'),
      ]);
      expect(toolResults.role, equals('user'));

      // 6. Build the full conversation messages list
      final messages = [userMessage, assistantParam, toolResults];
      expect(messages.length, equals(3));
      expect(messages[0].role, equals('user'));
      expect(messages[1].role, equals('assistant'));
      expect(messages[2].role, equals('user'));
    });
  });
}
