/// Controls how the model uses tools.
sealed class ToolChoice {
  const ToolChoice();
  Map<String, dynamic> toJson();
}

/// Let the model decide whether to use a tool.
class ToolChoiceAuto extends ToolChoice {
  const ToolChoiceAuto();
  @override
  Map<String, dynamic> toJson() => {'type': 'auto'};
}

/// Force the model to use any available tool.
class ToolChoiceAny extends ToolChoice {
  const ToolChoiceAny();
  @override
  Map<String, dynamic> toJson() => {'type': 'any'};
}

/// Force the model to use a specific tool by name.
class ToolChoiceSpecific extends ToolChoice {
  final String name;
  const ToolChoiceSpecific(this.name);
  @override
  Map<String, dynamic> toJson() => {'type': 'tool', 'name': name};
}

/// Prevent the model from using any tools.
class ToolChoiceNone extends ToolChoice {
  const ToolChoiceNone();
  @override
  Map<String, dynamic> toJson() => {'type': 'none'};
}
