import 'message_param.dart';
import '../tools/tool.dart';
import '../tools/tool_choice.dart';

/// Extended thinking configuration.
class ThinkingConfig {
  final String type; // 'enabled', 'disabled', 'auto'
  final int? budgetTokens;

  const ThinkingConfig._({required this.type, this.budgetTokens});

  const ThinkingConfig.enabled({int budgetTokens = 1024})
      : this._(type: 'enabled', budgetTokens: budgetTokens);

  const ThinkingConfig.disabled() : this._(type: 'disabled');

  const ThinkingConfig.auto({int? budgetTokens})
      : this._(type: 'auto', budgetTokens: budgetTokens);

  Map<String, dynamic> toJson() => {
        'type': type,
        if (budgetTokens != null) 'budget_tokens': budgetTokens,
      };
}

/// Request parameters for the Messages API.
class CreateMessageRequest {
  final String model;
  final int maxTokens;
  final List<MessageParam> messages;
  final String? systemPrompt;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;
  final ThinkingConfig? thinking;
  final int? temperature;
  final Map<String, dynamic>? metadata;

  const CreateMessageRequest({
    required this.model,
    required this.maxTokens,
    required this.messages,
    this.systemPrompt,
    this.tools,
    this.toolChoice,
    this.thinking,
    this.temperature,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': false,
    };
    if (systemPrompt != null) map['system'] = systemPrompt;
    if (tools != null) map['tools'] = tools!.map((t) => t.toJson()).toList();
    if (toolChoice != null) map['tool_choice'] = toolChoice!.toJson();
    if (thinking != null) map['thinking'] = thinking!.toJson();
    if (temperature != null) map['temperature'] = temperature;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }

  Map<String, dynamic> toStreamJson() {
    final map = toJson();
    map['stream'] = true;
    return map;
  }
}
