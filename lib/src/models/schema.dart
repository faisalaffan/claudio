import 'package:meta/meta.dart';

/// Type alias for a JSON Schema representation.
///
/// A [JsonSchema] is a `Map<String, dynamic>` that conforms to the
/// JSON Schema specification used by the Anthropic API for tool
/// input schemas.
typedef JsonSchema = Map<String, dynamic>;

// ---------------------------------------------------------------------------
// SchemaProperty (sealed)
// ---------------------------------------------------------------------------

/// A type-safe representation of a JSON Schema property.
///
/// Use the factory constructors to create properties of different types:
/// - [SchemaProperty.string] — `{"type": "string"}`, with optional `enum`
/// - [SchemaProperty.number] — `{"type": "number"}`
/// - [SchemaProperty.integer] — `{"type": "integer"}`
/// - [SchemaProperty.boolean] — `{"type": "boolean"}`
/// - [SchemaProperty.array] — `{"type": "array", "items": ...}`
/// - [SchemaProperty.object] — `{"type": "object", "properties": ...}`
///
/// Each variant can carry an optional [description].
///
/// Example:
/// ```dart
/// final prop = SchemaProperty.string(
///   description: 'Customer name',
///   enumValues: ['Alice', 'Bob'],
/// );
/// ```
@immutable
sealed class SchemaProperty {
  /// Optional human-readable description of this property.
  String? get description;

  const SchemaProperty();

  /// Creates a string schema property.
  ///
  /// Optionally accepts [enumValues] to restrict the allowed values.
  factory SchemaProperty.string({
    String? description,
    List<String>? enumValues,
  }) = StringSchemaProperty;

  /// Creates a number (floating-point) schema property.
  factory SchemaProperty.number({String? description}) =
      NumberSchemaProperty;

  /// Creates an integer schema property.
  factory SchemaProperty.integer({String? description}) =
      IntegerSchemaProperty;

  /// Creates a boolean schema property.
  factory SchemaProperty.boolean({String? description}) =
      BooleanSchemaProperty;

  /// Creates an array schema property with the given [items] type.
  factory SchemaProperty.array({
    required SchemaProperty items,
    String? description,
  }) = ArraySchemaProperty;

  /// Creates an object schema property with the given [properties].
  ///
  /// [required] lists the property names that are mandatory.
  factory SchemaProperty.object({
    required Map<String, SchemaProperty> properties,
    List<String>? required,
    String? description,
  }) = ObjectSchemaProperty;

  /// Creates a [SchemaProperty] from a JSON Schema map.
  ///
  /// Supports all types: `string`, `number`, `integer`, `boolean`,
  /// `array`, and `object`. Throws [ArgumentError] for unknown types.
  factory SchemaProperty.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final description = json['description'] as String?;

    return switch (type) {
      'string' => SchemaProperty.string(
          description: description,
          enumValues: (json['enum'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
        ),
      'number' => SchemaProperty.number(description: description),
      'integer' => SchemaProperty.integer(description: description),
      'boolean' => SchemaProperty.boolean(description: description),
      'array' => SchemaProperty.array(
          items: SchemaProperty.fromJson(
            json['items'] as Map<String, dynamic>,
          ),
          description: description,
        ),
      'object' => _objectFromJson(json, description),
      _ => throw ArgumentError('Unknown schema type: $type'),
    };
  }

  /// Converts this [SchemaProperty] to a JSON Schema map.
  JsonSchema toJson();

  /// Helper to parse an object schema from JSON.
  static ObjectSchemaProperty _objectFromJson(
    Map<String, dynamic> json,
    String? description,
  ) {
    final rawProps = json['properties'] as Map<String, dynamic>? ?? {};
    final properties = rawProps.map(
      (key, value) => MapEntry(
        key,
        SchemaProperty.fromJson(value as Map<String, dynamic>),
      ),
    );
    final required = (json['required'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();

    return ObjectSchemaProperty(
      properties: properties,
      required: required,
      description: description,
    );
  }
}

// ---------------------------------------------------------------------------
// StringSchemaProperty
// ---------------------------------------------------------------------------

/// A JSON Schema property of type `string`.
///
/// Optionally restricts values to a set of [enumValues].
@immutable
class StringSchemaProperty extends SchemaProperty {
  @override
  final String? description;

  /// The allowed enum values, or `null` if unrestricted.
  final List<String>? enumValues;

  /// Creates a [StringSchemaProperty].
  const StringSchemaProperty({this.description, this.enumValues});

  @override
  JsonSchema toJson() {
    final json = <String, dynamic>{'type': 'string'};
    if (description != null) json['description'] = description;
    if (enumValues != null) json['enum'] = enumValues;
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StringSchemaProperty) return false;
    if (other.description != description) return false;
    if (other.enumValues == null && enumValues == null) return true;
    if (other.enumValues == null || enumValues == null) return false;
    if (other.enumValues!.length != enumValues!.length) return false;
    for (var i = 0; i < enumValues!.length; i++) {
      if (other.enumValues![i] != enumValues![i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        'string',
        description,
        enumValues == null ? null : Object.hashAll(enumValues!),
      );

  @override
  String toString() =>
      'SchemaProperty.string(description: $description, enumValues: $enumValues)';
}

// ---------------------------------------------------------------------------
// NumberSchemaProperty
// ---------------------------------------------------------------------------

/// A JSON Schema property of type `number` (floating-point).
@immutable
class NumberSchemaProperty extends SchemaProperty {
  @override
  final String? description;

  /// Creates a [NumberSchemaProperty].
  const NumberSchemaProperty({this.description});

  @override
  JsonSchema toJson() {
    final json = <String, dynamic>{'type': 'number'};
    if (description != null) json['description'] = description;
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NumberSchemaProperty && other.description == description;
  }

  @override
  int get hashCode => Object.hash('number', description);

  @override
  String toString() => 'SchemaProperty.number(description: $description)';
}

// ---------------------------------------------------------------------------
// IntegerSchemaProperty
// ---------------------------------------------------------------------------

/// A JSON Schema property of type `integer`.
@immutable
class IntegerSchemaProperty extends SchemaProperty {
  @override
  final String? description;

  /// Creates an [IntegerSchemaProperty].
  const IntegerSchemaProperty({this.description});

  @override
  JsonSchema toJson() {
    final json = <String, dynamic>{'type': 'integer'};
    if (description != null) json['description'] = description;
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IntegerSchemaProperty && other.description == description;
  }

  @override
  int get hashCode => Object.hash('integer', description);

  @override
  String toString() => 'SchemaProperty.integer(description: $description)';
}

// ---------------------------------------------------------------------------
// BooleanSchemaProperty
// ---------------------------------------------------------------------------

/// A JSON Schema property of type `boolean`.
@immutable
class BooleanSchemaProperty extends SchemaProperty {
  @override
  final String? description;

  /// Creates a [BooleanSchemaProperty].
  const BooleanSchemaProperty({this.description});

  @override
  JsonSchema toJson() {
    final json = <String, dynamic>{'type': 'boolean'};
    if (description != null) json['description'] = description;
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BooleanSchemaProperty && other.description == description;
  }

  @override
  int get hashCode => Object.hash('boolean', description);

  @override
  String toString() => 'SchemaProperty.boolean(description: $description)';
}

// ---------------------------------------------------------------------------
// ArraySchemaProperty
// ---------------------------------------------------------------------------

/// A JSON Schema property of type `array`.
///
/// The [items] field describes the schema of each element in the array.
@immutable
class ArraySchemaProperty extends SchemaProperty {
  /// The schema for array elements.
  final SchemaProperty items;

  @override
  final String? description;

  /// Creates an [ArraySchemaProperty] with the given [items] schema.
  const ArraySchemaProperty({required this.items, this.description});

  @override
  JsonSchema toJson() {
    final json = <String, dynamic>{
      'type': 'array',
      'items': items.toJson(),
    };
    if (description != null) json['description'] = description;
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArraySchemaProperty &&
        other.items == items &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash('array', items, description);

  @override
  String toString() =>
      'SchemaProperty.array(items: $items, description: $description)';
}

// ---------------------------------------------------------------------------
// ObjectSchemaProperty
// ---------------------------------------------------------------------------

/// A JSON Schema property of type `object`.
///
/// Contains named [properties] and an optional list of [required] field names.
/// Supports unlimited nesting depth.
@immutable
class ObjectSchemaProperty extends SchemaProperty {
  /// The named properties of this object schema.
  final Map<String, SchemaProperty> properties;

  /// The list of required property names, or `null` if none are required.
  final List<String>? required;

  @override
  final String? description;

  /// Creates an [ObjectSchemaProperty] with the given [properties].
  const ObjectSchemaProperty({
    required this.properties,
    this.required,
    this.description,
  });

  @override
  JsonSchema toJson() {
    final json = <String, dynamic>{
      'type': 'object',
      'properties': properties.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
    if (required != null && required!.isNotEmpty) {
      json['required'] = required;
    }
    if (description != null) json['description'] = description;
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObjectSchemaProperty) return false;
    if (other.description != description) return false;
    // Compare required lists
    if (other.required == null && required == null) {
      // both null, ok
    } else if (other.required == null || required == null) {
      return false;
    } else {
      if (other.required!.length != required!.length) return false;
      for (var i = 0; i < required!.length; i++) {
        if (other.required![i] != required![i]) return false;
      }
    }
    // Compare properties maps
    if (other.properties.length != properties.length) return false;
    for (final key in properties.keys) {
      if (!other.properties.containsKey(key)) return false;
      if (other.properties[key] != properties[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        'object',
        description,
        required == null ? null : Object.hashAll(required!),
        Object.hashAll(properties.keys),
      );

  @override
  String toString() =>
      'SchemaProperty.object(properties: $properties, required: $required, '
      'description: $description)';
}

// ---------------------------------------------------------------------------
// SchemaBuilder
// ---------------------------------------------------------------------------

/// A fluent builder for constructing JSON Schema maps.
///
/// Use [SchemaBuilder] to create top-level `object` or `array` schemas
/// that can be used as tool input schemas.
///
/// Example:
/// ```dart
/// final schema = SchemaBuilder().object(
///   properties: {
///     'name': SchemaProperty.string(description: 'User name'),
///     'age': SchemaProperty.integer(),
///   },
///   required: ['name'],
/// );
///
/// final jsonSchema = schema.toJson();
/// // {"type": "object", "properties": {"name": ...}, "required": ["name"]}
/// ```
class SchemaBuilder {
  SchemaProperty? _root;

  /// Creates a new [SchemaBuilder].
  SchemaBuilder();

  /// Sets the root schema to an object type with the given [properties].
  ///
  /// Returns `this` for fluent chaining.
  SchemaBuilder object({
    required Map<String, SchemaProperty> properties,
    List<String>? required,
    String? description,
  }) {
    _root = SchemaProperty.object(
      properties: properties,
      required: required,
      description: description,
    );
    return this;
  }

  /// Sets the root schema to an array type with the given [items] schema.
  ///
  /// Returns `this` for fluent chaining.
  SchemaBuilder array({
    required SchemaProperty items,
    String? description,
  }) {
    _root = SchemaProperty.array(
      items: items,
      description: description,
    );
    return this;
  }

  /// Builds and returns the JSON Schema as a [JsonSchema] map.
  ///
  /// Throws [StateError] if neither [object] nor [array] has been called.
  JsonSchema toJson() {
    if (_root == null) {
      throw StateError(
        'SchemaBuilder has no root schema. '
        'Call object() or array() before toJson().',
      );
    }
    return _root!.toJson();
  }

  /// Alias for [toJson] — builds and returns the JSON Schema map.
  JsonSchema build() => toJson();
}
