// Demo script to generate mock terminal output for pub.dev screenshot.
// Not part of the library — standalone runnable for screenshot generation only.
// Regenerate screenshot: dart run scripts/demo_output.dart

const reset = '\x1B[0m';
const bold = '\x1B[1m';
const green = '\x1B[32m';
const cyan = '\x1B[36m';
const gray = '\x1B[90m';

void main() {
  print('$gray\$ dart run example/main.dart$reset\n');

  print(
      '$cyan[claudio]$reset ${bold}Anthropic$reset → claude-sonnet-4-20250514');
  print('$green✓$reset Messages API ready\n');

  final output = '''
Hello! I'm Claude, an AI assistant created by Anthropic.
I'd be happy to help you with whatever you need today.

$gray--- Stats ---$reset
Model: claude-sonnet-4-20250514
Input tokens: 10
Output tokens: 32
Stop reason: end_turn
''';

  print(output.trim());

  print('\n$gray\$ dart run example/main.dart --provider deepseek$reset\n');
  print('$cyan[claudio]$reset ${bold}DeepSeek$reset → deepseek-chat');
  print('$green✓$reset Messages API ready\n');

  print('Hello! I am DeepSeek, how can I assist you?\n');

  print('$gray--- Stats ---$reset');
  print('Model: deepseek-chat');
  print('Input tokens: 8');
  print('Output tokens: 12');
  print('Stop reason: end_turn');
}
