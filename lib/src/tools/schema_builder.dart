import 'schema_property.dart';

/// Fluent builder for JSON Schema construction.
class SchemaBuilder {
  String? _type;
  String? _description;
  final Map<String, SchemaProperty> _properties = {};
  final List<String> _required = [];
  SchemaProperty? _items;

  SchemaBuilder object({
    required Map<String, SchemaProperty> properties,
    List<String>? required,
    String? description,
  }) {
    _type = 'object';
    _description = description;
    _properties.addAll(properties);
    if (required != null) _required.addAll(required);
    return this;
  }

  SchemaBuilder array({required SchemaProperty items, String? description}) {
    _type = 'array';
    _description = description;
    _items = items;
    return this;
  }

  Map<String, dynamic> build() {
    final map = <String, dynamic>{};
    if (_type != null) map['type'] = _type;
    if (_description != null) map['description'] = _description;
    if (_properties.isNotEmpty) {
      map['properties'] = _properties.map((k, v) => MapEntry(k, v.toJson()));
    }
    if (_required.isNotEmpty) map['required'] = _required;
    if (_items != null) map['items'] = _items!.toJson();
    return map;
  }
}
