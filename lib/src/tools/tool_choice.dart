/// Controls how the model uses tools.
sealed class ToolChoice {
  const ToolChoice();
  Map<String, dynamic> toJson();
}

class ToolChoiceAuto extends ToolChoice {
  const ToolChoiceAuto();
  @override
  Map<String, dynamic> toJson() => {'type': 'auto'};
}

class ToolChoiceAny extends ToolChoice {
  const ToolChoiceAny();
  @override
  Map<String, dynamic> toJson() => {'type': 'any'};
}

class ToolChoiceSpecific extends ToolChoice {
  final String name;
  const ToolChoiceSpecific(this.name);
  @override
  Map<String, dynamic> toJson() => {'type': 'tool', 'name': name};
}

class ToolChoiceNone extends ToolChoice {
  const ToolChoiceNone();
  @override
  Map<String, dynamic> toJson() => {'type': 'none'};
}
