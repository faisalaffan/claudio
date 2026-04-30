import 'package:meta/meta.dart';

import 'message.dart';
import 'thinking.dart';
import 'tool.dart';

/// A request to create a message via the Anthropic Messages API.
///
/// Contains all parameters accepted by the `POST /v1/messages` endpoint.
/// Required fields are [model], [maxTokens], and [messages]. All other
/// fields are optional and will be omitted from the serialized JSON
/// when `null`.
///
/// The [stream] field is internal to the SDK — it defaults to `false`
/// and is set to `true` automatically when using `createStream()`.
///
/// Example:
/// ```dart
/// final request = CreateMessageRequest(
///   model: 'claude-sonnet-4-20250514',
///   maxTokens: 1024,
///   messages: [
///     MessageParam(role: 'user', content: 'Hello!'),
///   ],
///   systemPrompt: 'You are a helpful assistant.',
/// );
/// ```
///
/// Example JSON output:
/// ```json
/// {
///   "model": "claude-sonnet-4-20250514",
///   "max_tokens": 1024,
///   "system": "You are a helpful assistant.",
///   "messages": [{"role": "user", "content": "Hello!"}],
///   "stream": false
/// }
/// ```
@immutable
class CreateMessageRequest {
  /// The model to use for generating the response (e.g.
  /// `"claude-sonnet-4-20250514"`).
  final String model;

  /// The maximum number of tokens the model may generate.
  final int maxTokens;

  /// The conversation messages to send to the API.
  final List<MessageParam> messages;

  /// An optional system prompt that sets the model's behavior.
  ///
  /// Serialized as `"system"` in the JSON payload.
  final String? systemPrompt;

  /// An optional list of tool definitions the model may use.
  final List<Tool>? tools;

  /// An optional tool choice configuration that controls how the model
  /// selects which tool to use.
  final ToolChoice? toolChoice;

  /// An optional extended thinking configuration.
  final ThinkingConfig? thinking;

  /// An optional list of stop sequences that cause the model to stop
  /// generating when encountered.
  final List<String>? stopSequences;

  /// An optional sampling temperature (0.0–1.0).
  final double? temperature;

  /// An optional nucleus sampling parameter (0.0–1.0).
  final double? topP;

  /// An optional top-k sampling parameter.
  final int? topK;

  /// Whether to use streaming for this request.
  ///
  /// This is an internal field set by the SDK — defaults to `false`
  /// and is set to `true` when using `createStream()`.
  final bool stream;

  /// Creates a [CreateMessageRequest] with the given parameters.
  ///
  /// [model], [maxTokens], and [messages] are required.
  /// All other parameters are optional.
  const CreateMessageRequest({
    required this.model,
    required this.maxTokens,
    required this.messages,
    this.systemPrompt,
    this.tools,
    this.toolChoice,
    this.thinking,
    this.stopSequences,
    this.temperature,
    this.topP,
    this.topK,
    this.stream = false,
  });

  /// Converts this request to a JSON map matching the Anthropic API format.
  ///
  /// Field name mapping (Dart camelCase → API snake_case):
  /// - [maxTokens] → `max_tokens`
  /// - [systemPrompt] → `system`
  /// - [toolChoice] → `tool_choice`
  /// - [stopSequences] → `stop_sequences`
  /// - [topP] → `top_p`
  /// - [topK] → `top_k`
  ///
  /// Optional fields are omitted from the output when `null`.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': stream,
    };

    if (systemPrompt != null) {
      json['system'] = systemPrompt;
    }
    if (tools != null) {
      json['tools'] = tools!.map((t) => t.toJson()).toList();
    }
    if (toolChoice != null) {
      json['tool_choice'] = toolChoice!.toJson();
    }
    if (thinking != null) {
      json['thinking'] = thinking!.toJson();
    }
    if (stopSequences != null) {
      json['stop_sequences'] = stopSequences;
    }
    if (temperature != null) {
      json['temperature'] = temperature;
    }
    if (topP != null) {
      json['top_p'] = topP;
    }
    if (topK != null) {
      json['top_k'] = topK;
    }

    return json;
  }

  /// Creates a copy of this request with the given fields replaced.
  CreateMessageRequest copyWith({
    String? model,
    int? maxTokens,
    List<MessageParam>? messages,
    String? systemPrompt,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    ThinkingConfig? thinking,
    List<String>? stopSequences,
    double? temperature,
    double? topP,
    int? topK,
    bool? stream,
  }) {
    return CreateMessageRequest(
      model: model ?? this.model,
      maxTokens: maxTokens ?? this.maxTokens,
      messages: messages ?? this.messages,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      thinking: thinking ?? this.thinking,
      stopSequences: stopSequences ?? this.stopSequences,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      stream: stream ?? this.stream,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CreateMessageRequest) return false;
    if (other.model != model ||
        other.maxTokens != maxTokens ||
        other.systemPrompt != systemPrompt ||
        other.toolChoice != toolChoice ||
        other.thinking != thinking ||
        other.temperature != temperature ||
        other.topP != topP ||
        other.topK != topK ||
        other.stream != stream) {
      return false;
    }
    if (!_listEquals(other.messages, messages)) return false;
    if (!_nullableListEquals(other.tools, tools)) return false;
    if (!_nullableListEquals(other.stopSequences, stopSequences)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        model,
        maxTokens,
        Object.hashAll(messages),
        systemPrompt,
        tools == null ? null : Object.hashAll(tools!),
        toolChoice,
        thinking,
        stopSequences == null ? null : Object.hashAll(stopSequences!),
        temperature,
        topP,
        topK,
        stream,
      );

  @override
  String toString() => 'CreateMessageRequest('
      'model: $model, '
      'maxTokens: $maxTokens, '
      'messages: $messages, '
      'systemPrompt: $systemPrompt, '
      'tools: $tools, '
      'toolChoice: $toolChoice, '
      'thinking: $thinking, '
      'stopSequences: $stopSequences, '
      'temperature: $temperature, '
      'topP: $topP, '
      'topK: $topK, '
      'stream: $stream)';
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Compares two lists for element-wise equality.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Compares two nullable lists for element-wise equality.
bool _nullableListEquals<T>(List<T>? a, List<T>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return _listEquals(a, b);
}
