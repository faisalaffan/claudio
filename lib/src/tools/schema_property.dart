/// Type-safe JSON Schema property definition.
class SchemaProperty {
  final String type;
  final String? description;
  final Map<String, SchemaProperty>? properties;
  final SchemaProperty? items;
  final List<String>? enumValues;
  final List<String>? required;

  const SchemaProperty._({
    required this.type,
    this.description,
    this.properties,
    this.items,
    this.enumValues,
    this.required,
  });

  const SchemaProperty.string({String? description, List<String>? enumValues})
      : this._(
            type: 'string', description: description, enumValues: enumValues);

  const SchemaProperty.number({String? description})
      : this._(type: 'number', description: description);

  const SchemaProperty.integer({String? description})
      : this._(type: 'integer', description: description);

  const SchemaProperty.boolean({String? description})
      : this._(type: 'boolean', description: description);

  const SchemaProperty.array(
      {String? description, required SchemaProperty items})
      : this._(type: 'array', description: description, items: items);

  const SchemaProperty.object({
    String? description,
    required Map<String, SchemaProperty> properties,
    List<String>? required,
  }) : this._(
            type: 'object',
            description: description,
            properties: properties,
            required: required);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type};
    if (description != null) map['description'] = description;
    if (properties != null) {
      map['properties'] = properties!.map((k, v) => MapEntry(k, v.toJson()));
    }
    if (items != null) map['items'] = items!.toJson();
    if (enumValues != null) map['enum'] = enumValues;
    if (required != null) map['required'] = required;
    return map;
  }
}
