import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TextBlock', () {
    test('creates with correct type and text', () {
      const block = TextBlock(text: 'Hello, world!');
      expect(block.type, equals('text'));
      expect(block.text, equals('Hello, world!'));
    });

    test('toJson() produces correct JSON', () {
      const block = TextBlock(text: 'Hello');
      expect(block.toJson(), equals({'type': 'text', 'text': 'Hello'}));
    });

    test('equality works correctly', () {
      const a = TextBlock(text: 'Hello');
      const b = TextBlock(text: 'Hello');
      const c = TextBlock(text: 'World');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString() returns readable representation', () {
      const block = TextBlock(text: 'Hi');
      expect(block.toString(), equals('TextBlock(text: Hi)'));
    });
  });

  group('ImageSource', () {
    test('creates with correct fields', () {
      const source = ImageSource(
        type: 'base64',
        mediaType: 'image/png',
        data: 'iVBOR...',
      );
      expect(source.type, equals('base64'));
      expect(source.mediaType, equals('image/png'));
      expect(source.data, equals('iVBOR...'));
    });

    test('fromJson() parses correctly', () {
      final source = ImageSource.fromJson({
        'type': 'url',
        'media_type': 'image/jpeg',
        'data': 'https://example.com/img.jpg',
      });
      expect(source.type, equals('url'));
      expect(source.mediaType, equals('image/jpeg'));
      expect(source.data, equals('https://example.com/img.jpg'));
    });

    test('toJson() produces correct JSON', () {
      const source = ImageSource(
        type: 'base64',
        mediaType: 'image/png',
        data: 'abc123',
      );
      expect(source.toJson(), equals({
        'type': 'base64',
        'media_type': 'image/png',
        'data': 'abc123',
      }));
    });

    test('equality works correctly', () {
      const a = ImageSource(type: 'base64', mediaType: 'image/png', data: 'x');
      const b = ImageSource(type: 'base64', mediaType: 'image/png', data: 'x');
      const c = ImageSource(type: 'url', mediaType: 'image/png', data: 'x');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ImageBlock', () {
    test('creates with correct type and source', () {
      const source = ImageSource(
        type: 'base64',
        mediaType: 'image/png',
        data: 'iVBOR...',
      );
      const block = ImageBlock(source: source);
      expect(block.type, equals('image'));
      expect(block.source, equals(source));
    });

    test('toJson() produces correct JSON', () {
      const block = ImageBlock(
        source: ImageSource(
          type: 'base64',
          mediaType: 'image/png',
          data: 'abc',
        ),
      );
      expect(block.toJson(), equals({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/png',
          'data': 'abc',
        },
      }));
    });

    test('equality works correctly', () {
      const a = ImageBlock(
        source: ImageSource(type: 'base64', mediaType: 'image/png', data: 'x'),
      );
      const b = ImageBlock(
        source: ImageSource(type: 'base64', mediaType: 'image/png', data: 'x'),
      );
      const c = ImageBlock(
        source: ImageSource(type: 'url', mediaType: 'image/png', data: 'x'),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('DocumentSource', () {
    test('creates with correct fields', () {
      const source = DocumentSource(
        type: 'base64',
        mediaType: 'application/pdf',
        data: 'JVBERi0...',
      );
      expect(source.type, equals('base64'));
      expect(source.mediaType, equals('application/pdf'));
      expect(source.data, equals('JVBERi0...'));
    });

    test('fromJson() parses correctly', () {
      final source = DocumentSource.fromJson({
        'type': 'url',
        'media_type': 'application/pdf',
        'data': 'https://example.com/doc.pdf',
      });
      expect(source.type, equals('url'));
      expect(source.mediaType, equals('application/pdf'));
    });

    test('toJson() produces correct JSON', () {
      const source = DocumentSource(
        type: 'base64',
        mediaType: 'application/pdf',
        data: 'abc',
      );
      expect(source.toJson(), equals({
        'type': 'base64',
        'media_type': 'application/pdf',
        'data': 'abc',
      }));
    });

    test('equality works correctly', () {
      const a = DocumentSource(
        type: 'base64',
        mediaType: 'application/pdf',
        data: 'x',
      );
      const b = DocumentSource(
        type: 'base64',
        mediaType: 'application/pdf',
        data: 'x',
      );
      const c = DocumentSource(
        type: 'url',
        mediaType: 'application/pdf',
        data: 'x',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('DocumentBlock', () {
    test('creates with correct type and source', () {
      const source = DocumentSource(
        type: 'base64',
        mediaType: 'application/pdf',
        data: 'JVBERi0...',
      );
      const block = DocumentBlock(source: source);
      expect(block.type, equals('document'));
      expect(block.source, equals(source));
    });

    test('toJson() produces correct JSON', () {
      const block = DocumentBlock(
        source: DocumentSource(
          type: 'base64',
          mediaType: 'application/pdf',
          data: 'abc',
        ),
      );
      expect(block.toJson(), equals({
        'type': 'document',
        'source': {
          'type': 'base64',
          'media_type': 'application/pdf',
          'data': 'abc',
        },
      }));
    });
  });

  group('ToolUseBlock', () {
    test('creates with correct type and fields', () {
      const block = ToolUseBlock(
        id: 'toolu_123',
        name: 'get_weather',
        input: {'location': 'SF'},
      );
      expect(block.type, equals('tool_use'));
      expect(block.id, equals('toolu_123'));
      expect(block.name, equals('get_weather'));
      expect(block.input, equals({'location': 'SF'}));
    });

    test('toJson() produces correct JSON', () {
      const block = ToolUseBlock(
        id: 'toolu_abc',
        name: 'search',
        input: {'query': 'dart', 'limit': 10},
      );
      expect(block.toJson(), equals({
        'type': 'tool_use',
        'id': 'toolu_abc',
        'name': 'search',
        'input': {'query': 'dart', 'limit': 10},
      }));
    });

    test('equality works with nested input maps', () {
      const a = ToolUseBlock(
        id: 'id1',
        name: 'tool',
        input: {
          'nested': {'key': 'value'},
          'list': [1, 2, 3],
        },
      );
      const b = ToolUseBlock(
        id: 'id1',
        name: 'tool',
        input: {
          'nested': {'key': 'value'},
          'list': [1, 2, 3],
        },
      );
      const c = ToolUseBlock(
        id: 'id1',
        name: 'tool',
        input: {
          'nested': {'key': 'different'},
          'list': [1, 2, 3],
        },
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ToolResultBlock', () {
    test('creates with correct type and fields', () {
      const block = ToolResultBlock(
        toolUseId: 'toolu_123',
        content: [TextBlock(text: '15 degrees')],
      );
      expect(block.type, equals('tool_result'));
      expect(block.toolUseId, equals('toolu_123'));
      expect(block.content.length, equals(1));
      expect(block.isError, isFalse);
    });

    test('defaults isError to false and content to empty list', () {
      const block = ToolResultBlock(toolUseId: 'toolu_123');
      expect(block.isError, isFalse);
      expect(block.content, isEmpty);
    });

    test('toJson() omits is_error when false', () {
      const block = ToolResultBlock(
        toolUseId: 'toolu_123',
        content: [TextBlock(text: 'result')],
      );
      final json = block.toJson();
      expect(json.containsKey('is_error'), isFalse);
      expect(json['tool_use_id'], equals('toolu_123'));
    });

    test('toJson() includes is_error when true', () {
      const block = ToolResultBlock(
        toolUseId: 'toolu_123',
        content: [TextBlock(text: 'error occurred')],
        isError: true,
      );
      final json = block.toJson();
      expect(json['is_error'], isTrue);
    });

    test('toJson() uses snake_case for tool_use_id', () {
      const block = ToolResultBlock(toolUseId: 'toolu_abc');
      final json = block.toJson();
      expect(json.containsKey('tool_use_id'), isTrue);
      expect(json.containsKey('toolUseId'), isFalse);
    });

    test('equality works with content list', () {
      const a = ToolResultBlock(
        toolUseId: 'id1',
        content: [TextBlock(text: 'a'), TextBlock(text: 'b')],
      );
      const b = ToolResultBlock(
        toolUseId: 'id1',
        content: [TextBlock(text: 'a'), TextBlock(text: 'b')],
      );
      const c = ToolResultBlock(
        toolUseId: 'id1',
        content: [TextBlock(text: 'a')],
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ThinkingBlock', () {
    test('creates with correct type and fields', () {
      const block = ThinkingBlock(
        thinking: 'Let me think...',
        signature: 'sig123',
      );
      expect(block.type, equals('thinking'));
      expect(block.thinking, equals('Let me think...'));
      expect(block.signature, equals('sig123'));
    });

    test('toJson() produces correct JSON', () {
      const block = ThinkingBlock(
        thinking: 'Step 1...',
        signature: 'abc',
      );
      expect(block.toJson(), equals({
        'type': 'thinking',
        'thinking': 'Step 1...',
        'signature': 'abc',
      }));
    });

    test('equality works correctly', () {
      const a = ThinkingBlock(thinking: 'x', signature: 'y');
      const b = ThinkingBlock(thinking: 'x', signature: 'y');
      const c = ThinkingBlock(thinking: 'x', signature: 'z');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('RedactedThinkingBlock', () {
    test('creates with correct type and data', () {
      const block = RedactedThinkingBlock(data: 'opaque-data');
      expect(block.type, equals('redacted_thinking'));
      expect(block.data, equals('opaque-data'));
    });

    test('toJson() produces correct JSON', () {
      const block = RedactedThinkingBlock(data: 'redacted');
      expect(block.toJson(), equals({
        'type': 'redacted_thinking',
        'data': 'redacted',
      }));
    });

    test('equality works correctly', () {
      const a = RedactedThinkingBlock(data: 'x');
      const b = RedactedThinkingBlock(data: 'x');
      const c = RedactedThinkingBlock(data: 'y');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ContentBlock sealed class', () {
    test('all subclasses are ContentBlock instances', () {
      const blocks = <ContentBlock>[
        TextBlock(text: 'hello'),
        ImageBlock(
          source: ImageSource(
            type: 'base64',
            mediaType: 'image/png',
            data: 'abc',
          ),
        ),
        DocumentBlock(
          source: DocumentSource(
            type: 'base64',
            mediaType: 'application/pdf',
            data: 'abc',
          ),
        ),
        ToolUseBlock(id: 'id', name: 'tool', input: {}),
        ToolResultBlock(toolUseId: 'id'),
        ThinkingBlock(thinking: 'think', signature: 'sig'),
        RedactedThinkingBlock(data: 'data'),
      ];

      for (final block in blocks) {
        expect(block, isA<ContentBlock>());
      }
      expect(blocks.length, equals(7));
    });

    test('switch exhaustiveness works on sealed class', () {
      const ContentBlock block = TextBlock(text: 'test');
      final result = switch (block) {
        TextBlock() => 'text',
        ImageBlock() => 'image',
        DocumentBlock() => 'document',
        ToolUseBlock() => 'tool_use',
        ToolResultBlock() => 'tool_result',
        ThinkingBlock() => 'thinking',
        RedactedThinkingBlock() => 'redacted_thinking',
      };
      expect(result, equals('text'));
    });

    test('each subclass has unique type value', () {
      final types = <String>{
        const TextBlock(text: '').type,
        const ImageBlock(
          source: ImageSource(type: 'base64', mediaType: 'image/png', data: ''),
        ).type,
        const DocumentBlock(
          source: DocumentSource(
            type: 'base64',
            mediaType: 'application/pdf',
            data: '',
          ),
        ).type,
        const ToolUseBlock(id: '', name: '', input: {}).type,
        const ToolResultBlock(toolUseId: '').type,
        const ThinkingBlock(thinking: '', signature: '').type,
        const RedactedThinkingBlock(data: '').type,
      };
      expect(types.length, equals(7));
    });
  });
}
