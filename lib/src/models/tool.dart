import 'package:meta/meta.dart';

import 'schema.dart';

// ---------------------------------------------------------------------------
// Tool
// ---------------------------------------------------------------------------

/// A tool definition that can be provided to the Anthropic Messages API.
///
/// Tools allow Claude to call external functions during a conversation.
/// Each tool has a [name], a human-readable [description], and an
/// [inputSchema] that defines the expected parameters using JSON Schema.
///
/// Example:
/// ```dart
/// final tool = Tool(
///   name: 'get_weather',
///   description: 'Get the weather for a location',
///   inputSchema: SchemaBuilder().object(
///     properties: {
///       'location': SchemaProperty.string(description: 'City name'),
///     },
///     required: ['location'],
///   ).build(),
/// );
/// ```
///
/// Example JSON:
/// ```json
/// {
///   "name": "get_weather",
///   "description": "Get the weather for a location",
///   "input_schema": {
///     "type": "object",
///     "properties": {
///       "location": {"type": "string", "description": "City name"}
///     },
///     "required": ["location"]
///   }
/// }
/// ```
@immutable
class Tool {
  /// The name of the tool (must match `[a-zA-Z0-9_-]+`).
  final String name;

  /// A human-readable description of what the tool does.
  final String description;

  /// The JSON Schema defining the tool's input parameters.
  final JsonSchema inputSchema;

  /// Creates a [Tool] with the given [name], [description], and [inputSchema].
  const Tool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Creates a [Tool] from a JSON map.
  ///
  /// The `input_schema` field is stored as-is (a [JsonSchema] map),
  /// since that is the format the API expects.
  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      name: json['name'] as String,
      description: json['description'] as String,
      inputSchema:
          Map<String, dynamic>.from(json['input_schema'] as Map),
    );
  }

  /// Converts this [Tool] to a JSON map.
  ///
  /// The Dart field `inputSchema` is serialized as `input_schema`
  /// (snake_case) to match the Anthropic API format.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'input_schema': inputSchema,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Tool) return false;
    if (other.name != name || other.description != description) return false;
    return _mapEquals(other.inputSchema, inputSchema);
  }

  @override
  int get hashCode => Object.hash(name, description, Object.hashAll(inputSchema.keys));

  @override
  String toString() =>
      'Tool(name: $name, description: $description, inputSchema: $inputSchema)';
}

// ---------------------------------------------------------------------------
// ToolChoice (sealed)
// ---------------------------------------------------------------------------

/// Controls how the model selects which tool to use.
///
/// The Anthropic API supports four tool choice modes:
/// - [ToolChoiceAuto]: The model decides whether to use a tool or respond directly.
/// - [ToolChoiceAny]: The model must use one of the provided tools.
/// - [ToolChoiceTool]: The model must use the specific named tool.
/// - [ToolChoiceNone]: The model must not use any tools.
///
/// [ToolChoiceAuto], [ToolChoiceAny], and [ToolChoiceTool] support an
/// optional [disableParallelToolUse] flag that restricts the model to
/// using at most one tool per response.
///
/// Example JSON:
/// ```json
/// {"type": "auto"}
/// {"type": "auto", "disable_parallel_tool_use": true}
/// {"type": "any"}
/// {"type": "tool", "name": "get_weather"}
/// {"type": "none"}
/// ```
@immutable
sealed class ToolChoice {
  /// The type identifier for JSON serialization.
  String get type;

  const ToolChoice();

  /// Creates a [ToolChoiceAuto] — the model decides whether to use a tool.
  const factory ToolChoice.auto({bool disableParallelToolUse}) =
      ToolChoiceAuto;

  /// Creates a [ToolChoiceAny] — the model must use one of the provided tools.
  const factory ToolChoice.any({bool disableParallelToolUse}) =
      ToolChoiceAny;

  /// Creates a [ToolChoiceTool] — the model must use the specified tool.
  const factory ToolChoice.tool({
    required String name,
    bool disableParallelToolUse,
  }) = ToolChoiceTool;

  /// Creates a [ToolChoiceNone] — the model must not use any tools.
  const factory ToolChoice.none() = ToolChoiceNone;

  /// Creates a [ToolChoice] from a JSON map.
  ///
  /// Throws [ArgumentError] if the `type` field is not recognised.
  factory ToolChoice.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'auto' => ToolChoiceAuto(
          disableParallelToolUse:
              json['disable_parallel_tool_use'] as bool? ?? false,
        ),
      'any' => ToolChoiceAny(
          disableParallelToolUse:
              json['disable_parallel_tool_use'] as bool? ?? false,
        ),
      'tool' => ToolChoiceTool(
          name: json['name'] as String,
          disableParallelToolUse:
              json['disable_parallel_tool_use'] as bool? ?? false,
        ),
      'none' => const ToolChoiceNone(),
      _ => throw ArgumentError('Unknown tool choice type: $type'),
    };
  }

  /// Converts this [ToolChoice] to a JSON map.
  Map<String, dynamic> toJson();
}

// ---------------------------------------------------------------------------
// ToolChoiceAuto
// ---------------------------------------------------------------------------

/// The model decides whether to use a tool or respond with text.
///
/// This is the default behavior when `tool_choice` is not specified.
@immutable
class ToolChoiceAuto extends ToolChoice {
  /// Whether to disable parallel tool use (defaults to `false`).
  final bool disableParallelToolUse;

  @override
  String get type => 'auto';

  /// Creates a [ToolChoiceAuto] with an optional [disableParallelToolUse] flag.
  const ToolChoiceAuto({this.disableParallelToolUse = false});

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (disableParallelToolUse) {
      json['disable_parallel_tool_use'] = true;
    }
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolChoiceAuto &&
        other.disableParallelToolUse == disableParallelToolUse;
  }

  @override
  int get hashCode => Object.hash(type, disableParallelToolUse);

  @override
  String toString() =>
      'ToolChoice.auto(disableParallelToolUse: $disableParallelToolUse)';
}

// ---------------------------------------------------------------------------
// ToolChoiceAny
// ---------------------------------------------------------------------------

/// The model must use one of the provided tools.
@immutable
class ToolChoiceAny extends ToolChoice {
  /// Whether to disable parallel tool use (defaults to `false`).
  final bool disableParallelToolUse;

  @override
  String get type => 'any';

  /// Creates a [ToolChoiceAny] with an optional [disableParallelToolUse] flag.
  const ToolChoiceAny({this.disableParallelToolUse = false});

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (disableParallelToolUse) {
      json['disable_parallel_tool_use'] = true;
    }
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolChoiceAny &&
        other.disableParallelToolUse == disableParallelToolUse;
  }

  @override
  int get hashCode => Object.hash(type, disableParallelToolUse);

  @override
  String toString() =>
      'ToolChoice.any(disableParallelToolUse: $disableParallelToolUse)';
}

// ---------------------------------------------------------------------------
// ToolChoiceTool
// ---------------------------------------------------------------------------

/// The model must use the specific named tool.
@immutable
class ToolChoiceTool extends ToolChoice {
  /// The name of the tool the model must use.
  final String name;

  /// Whether to disable parallel tool use (defaults to `false`).
  final bool disableParallelToolUse;

  @override
  String get type => 'tool';

  /// Creates a [ToolChoiceTool] with the given [name] and optional
  /// [disableParallelToolUse] flag.
  const ToolChoiceTool({
    required this.name,
    this.disableParallelToolUse = false,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
      'name': name,
    };
    if (disableParallelToolUse) {
      json['disable_parallel_tool_use'] = true;
    }
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolChoiceTool &&
        other.name == name &&
        other.disableParallelToolUse == disableParallelToolUse;
  }

  @override
  int get hashCode => Object.hash(type, name, disableParallelToolUse);

  @override
  String toString() =>
      'ToolChoice.tool(name: $name, disableParallelToolUse: $disableParallelToolUse)';
}

// ---------------------------------------------------------------------------
// ToolChoiceNone
// ---------------------------------------------------------------------------

/// The model must not use any tools and should respond with text only.
@immutable
class ToolChoiceNone extends ToolChoice {
  @override
  String get type => 'none';

  /// Creates a [ToolChoiceNone].
  const ToolChoiceNone();

  @override
  Map<String, dynamic> toJson() {
    return {'type': type};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolChoiceNone;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'ToolChoice.none()';
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Deep equality check for two maps (used by [Tool]).
bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final va = a[key];
    final vb = b[key];
    if (va is Map<String, dynamic> && vb is Map<String, dynamic>) {
      if (!_mapEquals(va, vb)) return false;
    } else if (va is List && vb is List) {
      if (!_listEquals(va, vb)) return false;
    } else if (va != vb) {
      return false;
    }
  }
  return true;
}

/// Deep equality check for two lists (used by [_mapEquals]).
bool _listEquals(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final va = a[i];
    final vb = b[i];
    if (va is Map<String, dynamic> && vb is Map<String, dynamic>) {
      if (!_mapEquals(va, vb)) return false;
    } else if (va is List && vb is List) {
      if (!_listEquals(va, vb)) return false;
    } else if (va != vb) {
      return false;
    }
  }
  return true;
}
