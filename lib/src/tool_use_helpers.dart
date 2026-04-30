import 'models/content_block.dart';
import 'models/message.dart';

// ---------------------------------------------------------------------------
// Extension: MessageToolUseExtension
// ---------------------------------------------------------------------------

/// Extension on [Message] providing helper methods for tool use workflows.
///
/// These helpers simplify building multi-turn tool use conversations
/// by providing convenient access to tool use blocks and conversion
/// utilities.
///
/// Example:
/// ```dart
/// final response = await client.messages.create(request);
/// if (response.hasToolUse) {
///   final toolBlocks = response.toolUseBlocks;
///   // Execute tools locally...
///   final assistantParam = response.toAssistantParam();
///   // Build next turn with tool results...
/// }
/// ```
extension MessageToolUseExtension on Message {
  /// Returns `true` if this message contains any [ToolUseBlock].
  ///
  /// Useful for checking whether the model wants to call tools
  /// before processing the response.
  bool get hasToolUse => content.any((block) => block is ToolUseBlock);

  /// Converts this response [Message] to a [MessageParam] suitable for
  /// including in the next turn's message list.
  ///
  /// The resulting [MessageParam] has `role: 'assistant'` and contains
  /// the same content blocks as this message. This is needed when
  /// building multi-turn conversations where the assistant's response
  /// (including tool use blocks) must be sent back as context.
  MessageParam toAssistantParam() {
    return MessageParam(
      role: 'assistant',
      content: List<ContentBlock>.unmodifiable(content),
    );
  }
}

// ---------------------------------------------------------------------------
// Standalone helper functions
// ---------------------------------------------------------------------------

/// Creates a [ToolResultBlock] from the given parameters.
///
/// If [text] is provided and [content] is `null`, the text is automatically
/// wrapped in a `[TextBlock(text: text)]`. If both [text] and [content] are
/// provided, [content] takes precedence.
///
/// Set [isError] to `true` to indicate that the tool execution failed.
///
/// Example (text result):
/// ```dart
/// final result = createToolResult(
///   toolUseId: 'toolu_01A09q90qw90lq917835lq9',
///   text: '15 degrees',
/// );
/// ```
///
/// Example (error result):
/// ```dart
/// final result = createToolResult(
///   toolUseId: 'toolu_01A09q90qw90lq917835lq9',
///   text: 'Location not found',
///   isError: true,
/// );
/// ```
///
/// Example (rich content):
/// ```dart
/// final result = createToolResult(
///   toolUseId: 'toolu_01A09q90qw90lq917835lq9',
///   content: [
///     TextBlock(text: 'Temperature: 15°C'),
///     TextBlock(text: 'Humidity: 60%'),
///   ],
/// );
/// ```
ToolResultBlock createToolResult({
  required String toolUseId,
  String? text,
  List<ContentBlock>? content,
  bool isError = false,
}) {
  final resolvedContent = content ?? (text != null ? [TextBlock(text: text)] : const <ContentBlock>[]);

  return ToolResultBlock(
    toolUseId: toolUseId,
    content: resolvedContent,
    isError: isError,
  );
}

/// Creates a [MessageParam] with `role: 'user'` containing the given
/// tool [results].
///
/// This is the standard way to send tool execution results back to the
/// model in a multi-turn tool use conversation. The message can contain
/// one or more [ToolResultBlock]s (for parallel tool use).
///
/// Example (single result):
/// ```dart
/// final toolResultMessage = createToolResultMessage([
///   createToolResult(
///     toolUseId: 'toolu_01A09q90qw90lq917835lq9',
///     text: '15 degrees',
///   ),
/// ]);
/// ```
///
/// Example (multiple results for parallel tool use):
/// ```dart
/// final toolResultMessage = createToolResultMessage([
///   createToolResult(toolUseId: 'toolu_01', text: '15 degrees'),
///   createToolResult(toolUseId: 'toolu_02', text: 'Sunny'),
/// ]);
/// ```
MessageParam createToolResultMessage(List<ToolResultBlock> results) {
  return MessageParam(
    role: 'user',
    content: List<ContentBlock>.from(results),
  );
}
