import 'content_block.dart';
import 'message_param.dart';

/// Create a tool result block from tool use ID and text.
ToolResultBlock createToolResult(
    {required String toolUseId, required String text}) {
  return ToolResultBlock(toolUseId: toolUseId, content: text);
}

/// Wraps tool results in a user MessageParam for conversation continuation.
MessageParam createToolResultMessage(List<ToolResultBlock> toolResults) {
  return MessageParam(role: 'user', content: toolResults);
}
