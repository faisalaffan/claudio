import 'content_block.dart';

/// A message in a conversation.
class MessageParam {
  final String role;
  final dynamic content; // String or List<ContentBlock>

  const MessageParam({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    if (content is String) {
      return {'role': role, 'content': content as String};
    }
    return {
      'role': role,
      'content': (content as List).map((b) => (b as ContentBlock).toJson()).toList(),
    };
  }
}
