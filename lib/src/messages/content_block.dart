/// Base sealed class for content blocks in messages.
sealed class ContentBlock {
  const ContentBlock();
}

/// Text content block from the model.
class TextBlock extends ContentBlock {
  final String text;

  const TextBlock({required this.text});

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(text: json['text'] as String);
  }

  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

/// Tool use request from the model.
class ToolUseBlock extends ContentBlock {
  final String id;
  final String name;
  final Map<String, dynamic> input;

  const ToolUseBlock({required this.id, required this.name, required this.input});

  factory ToolUseBlock.fromJson(Map<String, dynamic> json) {
    return ToolUseBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      input: json['input'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {'type': 'tool_use', 'id': id, 'name': name, 'input': input};
}

/// Tool result sent back to the model.
class ToolResultBlock extends ContentBlock {
  final String toolUseId;
  final String? content;
  final List<Map<String, dynamic>>? contentBlocks;

  const ToolResultBlock({required this.toolUseId, this.content, this.contentBlocks});

  Map<String, dynamic> toJson() => {
    'type': 'tool_result',
    'tool_use_id': toolUseId,
    if (content != null) 'content': content,
    if (contentBlocks != null) 'content': contentBlocks,
  };
}

/// Image content block (base64 or URL).
class ImageBlock extends ContentBlock {
  final String sourceType;
  final String mediaType;
  final String data;

  const ImageBlock({required this.sourceType, required this.mediaType, required this.data});

  Map<String, dynamic> toJson() => {
    'type': 'image',
    'source': {'type': sourceType, 'media_type': mediaType, 'data': data},
  };
}

/// Extended thinking block from the model.
class ThinkingBlock extends ContentBlock {
  final String thinking;
  final String signature;

  const ThinkingBlock({required this.thinking, required this.signature});

  factory ThinkingBlock.fromJson(Map<String, dynamic> json) {
    return ThinkingBlock(
      thinking: json['thinking'] as String,
      signature: json['signature'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'type': 'thinking', 'thinking': thinking, 'signature': signature};
}
