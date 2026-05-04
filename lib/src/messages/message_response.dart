import 'content_block.dart';
import 'message_param.dart';

/// Token usage information.
class Usage {
  final int inputTokens;
  final int outputTokens;

  const Usage({required this.inputTokens, required this.outputTokens});

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      inputTokens: json['input_tokens'] as int,
      outputTokens: json['output_tokens'] as int,
    );
  }
}

/// Full message response from the API.
class Message {
  final String id;
  final String model;
  final String stopReason;
  final String? stopSequence;
  final Usage usage;
  final List<ContentBlock> content;

  const Message({
    required this.id,
    required this.model,
    required this.stopReason,
    this.stopSequence,
    required this.usage,
    required this.content,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final contentList = (json['content'] as List)
        .map((c) => _parseContentBlock(c as Map<String, dynamic>))
        .toList();

    return Message(
      id: json['id'] as String,
      model: json['model'] as String,
      stopReason: json['stop_reason'] as String,
      stopSequence: json['stop_sequence'] as String?,
      usage: Usage.fromJson(json['usage'] as Map<String, dynamic>),
      content: contentList,
    );
  }

  static ContentBlock _parseContentBlock(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'text' => TextBlock.fromJson(json),
      'tool_use' => ToolUseBlock.fromJson(json),
      'thinking' => ThinkingBlock.fromJson(json),
      _ => TextBlock(text: json.toString()),
    };
  }

  String get text => content.whereType<TextBlock>().map((b) => b.text).join('\n');

  bool get hasToolUse => content.any((b) => b is ToolUseBlock);

  List<ToolUseBlock> get toolUseBlocks => content.whereType<ToolUseBlock>().toList();

  MessageParam toAssistantParam() {
    return MessageParam(role: 'assistant', content: content);
  }
}
