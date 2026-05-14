import 'package:claudio_sdk/src/tools/tool.dart';
import 'package:claudio_sdk/src/tools/tool_choice.dart';
import 'package:test/test.dart';

void main() {
  group('Tool', () {
    test('toJson with description', () {
      final tool = Tool(name: 'get_weather', description: 'Get weather', inputSchema: {'type': 'object'});
      final json = tool.toJson();
      expect(json['name'], 'get_weather');
      expect(json['description'], 'Get weather');
      expect(json['input_schema'], isA<Map<String, dynamic>>());
    });

    test('toJson without description', () {
      final tool = Tool(name: 'my_tool', inputSchema: {});
      expect(tool.toJson().containsKey('description'), false);
    });
  });

  group('ToolChoice', () {
    test('auto', () { expect(const ToolChoiceAuto().toJson(), {'type': 'auto'}); });
    test('any', () { expect(const ToolChoiceAny().toJson(), {'type': 'any'}); });
    test('specific tool', () {
      final tc = ToolChoiceSpecific('my_tool');
      expect(tc.toJson(), {'type': 'tool', 'name': 'my_tool'});
      expect(tc.name, 'my_tool');
    });
    test('none', () { expect(const ToolChoiceNone().toJson(), {'type': 'none'}); });
  });
}
