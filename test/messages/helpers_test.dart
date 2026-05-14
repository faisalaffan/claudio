import 'package:claudio_sdk/src/messages/content_block.dart';
import 'package:claudio_sdk/src/messages/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('createToolResult', () {
    test('creates ToolResultBlock with toolUseId and text', () {
      final result = createToolResult(toolUseId: 'toolu_01', text: 'Sunny, 30C');
      expect(result.toolUseId, 'toolu_01');
      expect(result.content, 'Sunny, 30C');
    });
  });

  group('createToolResultMessage', () {
    test('wraps tool results in user MessageParam', () {
      final results = [
        ToolResultBlock(toolUseId: 'toolu_01', content: 'Result 1'),
        ToolResultBlock(toolUseId: 'toolu_02', content: 'Result 2'),
      ];
      final param = createToolResultMessage(results);
      expect(param.role, 'user');
      expect(param.content, results);
    });
  });
}
