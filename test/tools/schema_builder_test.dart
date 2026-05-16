import 'package:claudio_sdk/src/tools/schema_builder.dart';
import 'package:claudio_sdk/src/tools/schema_property.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaProperty', () {
    test('string property', () {
      final p = SchemaProperty.string(
          description: 'A string', enumValues: ['a', 'b']);
      final json = p.toJson();
      expect(json['type'], 'string');
      expect(json['description'], 'A string');
      expect(json['enum'], ['a', 'b']);
    });

    test('nested object property', () {
      final p = SchemaProperty.object(
        description: 'Nested',
        properties: {
          'name': SchemaProperty.string(),
          'age': SchemaProperty.integer(),
        },
        required: ['name'],
      );
      final json = p.toJson();
      expect(json['type'], 'object');
      expect(json['properties']['name']['type'], 'string');
      expect(json['required'], ['name']);
    });

    test('array with items', () {
      final p = SchemaProperty.array(
        description: 'Array of strings',
        items: SchemaProperty.string(),
      );
      final json = p.toJson();
      expect(json['type'], 'array');
      expect(json['items']['type'], 'string');
    });

    test('number, boolean, integer types', () {
      expect(SchemaProperty.number().type, 'number');
      expect(SchemaProperty.boolean().type, 'boolean');
      expect(SchemaProperty.integer().type, 'integer');
    });
  });

  group('SchemaBuilder', () {
    test('simple object schema', () {
      final schema = SchemaBuilder().object(
        properties: {
          'location': SchemaProperty.string(description: 'City'),
          'unit': SchemaProperty.string(enumValues: ['celsius', 'fahrenheit']),
        },
        required: ['location'],
      ).build();

      expect(schema['type'], 'object');
      expect(schema['properties']['location']['type'], 'string');
      expect(schema['properties']['unit']['enum'], ['celsius', 'fahrenheit']);
      expect(schema['required'], ['location']);
    });

    test('deeply nested schema', () {
      final schema = SchemaBuilder().object(
        properties: {
          'customer': SchemaProperty.object(
            properties: {
              'name': SchemaProperty.string(),
              'address': SchemaProperty.object(
                properties: {
                  'street': SchemaProperty.string(),
                  'city': SchemaProperty.string(),
                },
                required: ['street'],
              ),
            },
            required: ['name'],
          ),
        },
        required: ['customer'],
      ).build();

      final address = schema['properties']['customer']['properties']['address'];
      expect(address['properties']['city']['type'], 'string');
    });
  });
}
