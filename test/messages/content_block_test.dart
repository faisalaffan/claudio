import 'package:claudio/src/messages/content_block.dart';
import 'package:test/test.dart';

void main() {
  group('TextBlock', () {
    test('fromJson creates TextBlock', () {
      final block = TextBlock.fromJson({'text': 'Hello'});
      expect(block.text, 'Hello');
    });

    test('toJson produces correct map', () {
      final block = TextBlock(text: 'Hello');
      expect(block.toJson(), {'type': 'text', 'text': 'Hello'});
    });
  });

  group('ToolUseBlock', () {
    test('fromJson and toJson', () {
      final block = ToolUseBlock.fromJson({
        'id': 'toolu_01',
        'name': 'get_weather',
        'input': {'location': 'Jakarta'},
      });
      expect(block.id, 'toolu_01');
      expect(block.name, 'get_weather');
      expect(block.input, {'location': 'Jakarta'});
      final json = block.toJson();
      expect(json['type'], 'tool_use');
    });
  });

  group('ToolResultBlock', () {
    test('toJson with content', () {
      final block = ToolResultBlock(toolUseId: 'toolu_01', content: 'Sunny, 30C');
      final json = block.toJson();
      expect(json['type'], 'tool_result');
      expect(json['tool_use_id'], 'toolu_01');
      expect(json['content'], 'Sunny, 30C');
    });
  });

  group('ImageBlock', () {
    test('toJson', () {
      final block = ImageBlock(sourceType: 'base64', mediaType: 'image/png', data: 'abc123');
      final json = block.toJson();
      expect(json['type'], 'image');
      expect(json['source']['data'], 'abc123');
    });
  });

  group('ThinkingBlock', () {
    test('fromJson and toJson', () {
      final block = ThinkingBlock(thinking: 'Hmm...', signature: 'sig123');
      final json = block.toJson();
      expect(json['type'], 'thinking');
      expect(json['thinking'], 'Hmm...');
      expect(json['signature'], 'sig123');
    });
  });
}
