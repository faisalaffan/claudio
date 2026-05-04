# claudio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build claudio — a multi-provider AI SDK for Dart/Flutter with Anthropic Messages API-compatible interface supporting Anthropic + DeepSeek.

**Architecture:** Single `ClaudioClient` with `ProviderAdapter` abstraction layer. Provider-specific adapters handle auth headers, base URLs, and feature validation. Everything else (models, streaming, tools, error handling) is provider-agnostic.

**Tech Stack:** Dart 3.0+, `http` package, `meta` for sealed classes. Tests: `test` + `mockito` + `kiri_check`.

---

### Task 1: Project Skeleton

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `.gitignore`
- Create: `lib/claudio.dart` (empty barrel)
- Create: `lib/src/client/provider.dart`
- Create: `test/client/provider_test.dart`

- [ ] **Step 1: Write pubspec.yaml**

```yaml
name: claudio
description: >-
  Multi-provider AI SDK for Dart/Flutter with Anthropic Messages API-compatible
  interface. Supports Anthropic, DeepSeek, and more.
version: 0.1.0
homepage: https://github.com/faisalaffan/claudio
repository: https://github.com/faisalaffan/claudio
issue_tracker: https://github.com/faisalaffan/claudio/issues

environment:
  sdk: ^3.0.0

dependencies:
  http: ^1.2.0
  meta: ^1.12.0

dev_dependencies:
  build_runner: ^2.4.0
  lints: ^5.1.1
  mockito: ^5.4.0
  test: ^1.25.0
```

- [ ] **Step 2: Write analysis_options.yaml**

```yaml
include: package:lints/dart.yaml
```

- [ ] **Step 3: Write .gitignore**

```
.dart_tool/
.packages
build/
pubspec.lock
.superpowers/
```

- [ ] **Step 4: Write Provider enum**

File: `lib/src/client/provider.dart`

```dart
/// Supported AI providers.
enum Provider {
  anthropic,
  deepseek,
}
```

- [ ] **Step 5: Write test for Provider**

File: `test/client/provider_test.dart`

```dart
import 'package:claudio/src/client/provider.dart';
import 'package:test/test.dart';

void main() {
  group('Provider', () {
    test('has anthropic and deepseek values', () {
      expect(Provider.values, containsAll([Provider.anthropic, Provider.deepseek]));
    });

    test('Provider.anthropic name is "anthropic"', () {
      expect(Provider.anthropic.name, 'anthropic');
    });

    test('Provider.deepseek name is "deepseek"', () {
      expect(Provider.deepseek.name, 'deepseek');
    });
  });
}
```

- [ ] **Step 6: Get dependencies and run test**

```bash
dart pub get
dart test test/client/provider_test.dart
```

Expected: 3 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml analysis_options.yaml .gitignore lib/ test/
git commit -m "feat: project skeleton with Provider enum"
```

---

### Task 2: Feature Enum + RetryPolicy

**Files:**
- Create: `lib/src/client/feature.dart`
- Create: `test/client/feature_test.dart`
- Create: `lib/src/client/retry_policy.dart`
- Create: `test/client/retry_policy_test.dart`

- [ ] **Step 1: Write Feature enum**

File: `lib/src/client/feature.dart`

```dart
/// Features that may or may not be supported by a provider.
enum Feature {
  extendedThinking,
  imageInput,
  toolUse,
  streaming,
  systemPrompt,
  promptCaching,
}
```

- [ ] **Step 2: Write Feature test**

File: `test/client/feature_test.dart`

```dart
import 'package:claudio/src/client/feature.dart';
import 'package:test/test.dart';

void main() {
  group('Feature', () {
    test('has all expected values', () {
      expect(Feature.values, containsAll([
        Feature.extendedThinking,
        Feature.imageInput,
        Feature.toolUse,
        Feature.streaming,
        Feature.systemPrompt,
        Feature.promptCaching,
      ]));
    });
  });
}
```

- [ ] **Step 3: Run test**

```bash
dart test test/client/feature_test.dart
```

Expected: PASS.

- [ ] **Step 4: Write RetryPolicy**

File: `lib/src/client/retry_policy.dart`

```dart
import 'dart:math';

/// Configuration for automatic retry with exponential backoff.
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;

  const RetryPolicy({
    this.maxRetries = 2,
    this.initialDelay = const Duration(seconds: 1),
  });

  /// Compute delay for attempt [n] (0-indexed).
  Duration delayForAttempt(int attempt) {
    final base = initialDelay.inMilliseconds * pow(2, attempt).toInt();
    final jitter = Random().nextInt(1000);
    return Duration(milliseconds: base + jitter);
  }
}
```

- [ ] **Step 5: Write RetryPolicy test**

File: `test/client/retry_policy_test.dart`

```dart
import 'package:claudio/src/client/retry_policy.dart';
import 'package:test/test.dart';

void main() {
  group('RetryPolicy', () {
    test('has defaults', () {
      const policy = RetryPolicy();
      expect(policy.maxRetries, 2);
      expect(policy.initialDelay, const Duration(seconds: 1));
    });

    test('custom values', () {
      const policy = RetryPolicy(maxRetries: 5, initialDelay: Duration(seconds: 3));
      expect(policy.maxRetries, 5);
      expect(policy.initialDelay, const Duration(seconds: 3));
    });

    test('delayForAttempt increases exponentially', () {
      const policy = RetryPolicy(maxRetries: 3);
      final d0 = policy.delayForAttempt(0);
      final d1 = policy.delayForAttempt(1);
      final d2 = policy.delayForAttempt(2);
      expect(d1.inMilliseconds, greaterThan(d0.inMilliseconds));
      expect(d2.inMilliseconds, greaterThan(d1.inMilliseconds));
    });

    test('delayForAttempt includes jitter', () {
      const policy = RetryPolicy();
      final delays = List.generate(10, (i) => policy.delayForAttempt(0));
      final unique = delays.toSet();
      expect(unique.length, greaterThan(1));
    });
  });
}
```

- [ ] **Step 6: Run tests**

```bash
dart test test/client/retry_policy_test.dart test/client/feature_test.dart
```

Expected: 5 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/src/client/feature.dart lib/src/client/retry_policy.dart test/client/
git commit -m "feat: add Feature enum and RetryPolicy with backoff"
```

---

### Task 3: Error Hierarchy

**Files:**
- Create: `lib/src/errors/claudio_exception.dart`
- Create: `lib/src/errors/authentication_exception.dart`
- Create: `lib/src/errors/rate_limit_exception.dart`
- Create: `lib/src/errors/invalid_request_exception.dart`
- Create: `lib/src/errors/api_exception.dart`
- Create: `lib/src/errors/network_exception.dart`
- Create: `lib/src/errors/stream_exception.dart`
- Create: `lib/src/errors/unsupported_feature_exception.dart`
- Create: `lib/src/errors/client_closed_exception.dart`
- Create: `test/errors/exceptions_test.dart`

- [ ] **Step 1: Write base exception**

File: `lib/src/errors/claudio_exception.dart`

```dart
/// Base class for all claudio exceptions.
abstract class ClaudioException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  const ClaudioException(this.message, {this.statusCode, this.requestId});

  @override
  String toString() => 'ClaudioException: $message';
}
```

- [ ] **Step 2: Write all exception subclasses**

File: `lib/src/errors/authentication_exception.dart`

```dart
import 'claudio_exception.dart';

class AuthenticationException extends ClaudioException {
  const AuthenticationException(super.message, {super.statusCode, super.requestId});
}
```

File: `lib/src/errors/rate_limit_exception.dart`

```dart
import 'claudio_exception.dart';

class RateLimitException extends ClaudioException {
  final Duration? retryAfter;
  const RateLimitException(super.message, {super.statusCode, super.requestId, this.retryAfter});
}
```

File: `lib/src/errors/invalid_request_exception.dart`

```dart
import 'claudio_exception.dart';

class InvalidRequestException extends ClaudioException {
  const InvalidRequestException(super.message, {super.statusCode, super.requestId});
}
```

File: `lib/src/errors/api_exception.dart`

```dart
import 'claudio_exception.dart';

class ApiException extends ClaudioException {
  const ApiException(super.message, {super.statusCode, super.requestId});
}
```

File: `lib/src/errors/network_exception.dart`

```dart
import 'claudio_exception.dart';

class NetworkException extends ClaudioException {
  const NetworkException(super.message, {super.statusCode, super.requestId});
}
```

File: `lib/src/errors/stream_exception.dart`

```dart
import 'claudio_exception.dart';

class StreamException extends ClaudioException {
  const StreamException(super.message, {super.statusCode, super.requestId});
}
```

File: `lib/src/errors/unsupported_feature_exception.dart`

```dart
import '../client/feature.dart';
import '../client/provider.dart';
import 'claudio_exception.dart';

class UnsupportedFeatureException extends ClaudioException {
  final Feature feature;
  final Provider provider;

  UnsupportedFeatureException({
    required this.feature,
    required this.provider,
  }) : super('Feature $feature is not supported by provider $provider');
}
```

File: `lib/src/errors/client_closed_exception.dart`

```dart
import 'claudio_exception.dart';

class ClientClosedException extends ClaudioException {
  const ClientClosedException() : super('Client has been closed');
}
```

- [ ] **Step 3: Write tests**

File: `test/errors/exceptions_test.dart`

```dart
import 'package:claudio/src/client/feature.dart';
import 'package:claudio/src/client/provider.dart';
import 'package:claudio/src/errors/claudio_exception.dart';
import 'package:claudio/src/errors/authentication_exception.dart';
import 'package:claudio/src/errors/rate_limit_exception.dart';
import 'package:claudio/src/errors/invalid_request_exception.dart';
import 'package:claudio/src/errors/api_exception.dart';
import 'package:claudio/src/errors/network_exception.dart';
import 'package:claudio/src/errors/stream_exception.dart';
import 'package:claudio/src/errors/unsupported_feature_exception.dart';
import 'package:claudio/src/errors/client_closed_exception.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudioException', () {
    test('AuthenticationException', () {
      final e = AuthenticationException('Invalid key', statusCode: 401);
      expect(e.statusCode, 401);
      expect(e.message, 'Invalid key');
      expect(e, isA<ClaudioException>());
    });

    test('RateLimitException with retryAfter', () {
      final e = RateLimitException('Too many', retryAfter: Duration(seconds: 30));
      expect(e.retryAfter, const Duration(seconds: 30));
    });

    test('InvalidRequestException', () {
      final e = InvalidRequestException('Bad input', statusCode: 400);
      expect(e.statusCode, 400);
      expect(e, isA<ClaudioException>());
    });

    test('ApiException', () {
      final e = ApiException('Server error', statusCode: 500);
      expect(e.statusCode, 500);
      expect(e, isA<ClaudioException>());
    });

    test('NetworkException', () {
      final e = NetworkException('Connection refused');
      expect(e.message, 'Connection refused');
      expect(e, isA<ClaudioException>());
    });

    test('StreamException', () {
      final e = StreamException('SSE connection lost');
      expect(e.message, 'SSE connection lost');
      expect(e, isA<ClaudioException>());
    });

    test('UnsupportedFeatureException', () {
      final e = UnsupportedFeatureException(
        feature: Feature.extendedThinking,
        provider: Provider.deepseek,
      );
      expect(e.feature, Feature.extendedThinking);
      expect(e.provider, Provider.deepseek);
      expect(e.message, contains('extendedThinking'));
      expect(e.message, contains('deepseek'));
    });

    test('ClientClosedException', () {
      final e = ClientClosedException();
      expect(e.message, contains('closed'));
      expect(e, isA<ClaudioException>());
    });
  });
}
```

- [ ] **Step 4: Run tests**

```bash
dart test test/errors/exceptions_test.dart
```

Expected: 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/errors/ test/errors/
git commit -m "feat: add typed exception hierarchy"
```

---

### Task 4: Content Block Models

**Files:**
- Create: `lib/src/messages/content_block.dart`
- Create: `test/messages/content_block_test.dart`

- [ ] **Step 1: Write ContentBlock types**

File: `lib/src/messages/content_block.dart`

```dart
/// Base sealed class for content blocks in messages.
sealed class ContentBlock {
  const ContentBlock();
}

/// Text content block from the model.
class TextBlock extends ContentBlock {
  final String text;

  const TextBlock({required this.text});

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(text: json['text'] as String);
  }

  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

/// Tool use request from the model.
class ToolUseBlock extends ContentBlock {
  final String id;
  final String name;
  final Map<String, dynamic> input;

  const ToolUseBlock({required this.id, required this.name, required this.input});

  factory ToolUseBlock.fromJson(Map<String, dynamic> json) {
    return ToolUseBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      input: json['input'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {'type': 'tool_use', 'id': id, 'name': name, 'input': input};
}

/// Tool result sent back to the model.
class ToolResultBlock extends ContentBlock {
  final String toolUseId;
  final String? content;
  final List<Map<String, dynamic>>? contentBlocks;

  const ToolResultBlock({required this.toolUseId, this.content, this.contentBlocks});

  Map<String, dynamic> toJson() => {
    'type': 'tool_result',
    'tool_use_id': toolUseId,
    if (content != null) 'content': content,
    if (contentBlocks != null) 'content': contentBlocks,
  };
}

/// Image content block (base64 or URL).
class ImageBlock extends ContentBlock {
  final String sourceType; // 'base64' or 'url'
  final String mediaType;
  final String data;

  const ImageBlock({required this.sourceType, required this.mediaType, required this.data});

  Map<String, dynamic> toJson() => {
    'type': 'image',
    'source': {'type': sourceType, 'media_type': mediaType, 'data': data},
  };
}

/// Extended thinking block from the model.
class ThinkingBlock extends ContentBlock {
  final String thinking;
  final String signature;

  const ThinkingBlock({required this.thinking, required this.signature});

  factory ThinkingBlock.fromJson(Map<String, dynamic> json) {
    return ThinkingBlock(
      thinking: json['thinking'] as String,
      signature: json['signature'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'type': 'thinking', 'thinking': thinking, 'signature': signature};
}
```

- [ ] **Step 2: Write tests**

File: `test/messages/content_block_test.dart`

```dart
import 'package:claudio/src/messages/content_block.dart';
import 'package:test/test.dart';

void main() {
  group('TextBlock', () {
    test('fromJson creates TextBlock', () {
      final block = TextBlock.fromJson({'text': 'Hello'});
      expect(block.text, 'Hello');
    });

    test('toJson produces correct map', () {
      final block = TextBlock(text: 'Hello');
      expect(block.toJson(), {'type': 'text', 'text': 'Hello'});
    });
  });

  group('ToolUseBlock', () {
    test('fromJson and toJson', () {
      final block = ToolUseBlock.fromJson({
        'id': 'toolu_01',
        'name': 'get_weather',
        'input': {'location': 'Jakarta'},
      });
      expect(block.id, 'toolu_01');
      expect(block.name, 'get_weather');
      expect(block.input, {'location': 'Jakarta'});
      final json = block.toJson();
      expect(json['type'], 'tool_use');
    });
  });

  group('ToolResultBlock', () {
    test('toJson with content', () {
      final block = ToolResultBlock(toolUseId: 'toolu_01', content: 'Sunny, 30C');
      final json = block.toJson();
      expect(json['type'], 'tool_result');
      expect(json['tool_use_id'], 'toolu_01');
      expect(json['content'], 'Sunny, 30C');
    });
  });

  group('ImageBlock', () {
    test('toJson', () {
      final block = ImageBlock(sourceType: 'base64', mediaType: 'image/png', data: 'abc123');
      final json = block.toJson();
      expect(json['type'], 'image');
      expect(json['source']['data'], 'abc123');
    });
  });

  group('ThinkingBlock', () {
    test('fromJson and toJson', () {
      final block = ThinkingBlock(thinking: 'Hmm...', signature: 'sig123');
      final json = block.toJson();
      expect(json['type'], 'thinking');
      expect(json['thinking'], 'Hmm...');
      expect(json['signature'], 'sig123');
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
dart test test/messages/content_block_test.dart
```

Expected: 6 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/src/messages/ test/messages/
git commit -m "feat: add content block models"
```

---

### Task 5: SchemaProperty + SchemaBuilder

**Files:**
- Create: `lib/src/tools/schema_property.dart`
- Create: `lib/src/tools/schema_builder.dart`
- Create: `test/tools/schema_builder_test.dart`

- [ ] **Step 1: Write SchemaProperty**

File: `lib/src/tools/schema_property.dart`

```dart
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
      : this._(type: 'string', description: description, enumValues: enumValues);

  const SchemaProperty.number({String? description})
      : this._(type: 'number', description: description);

  const SchemaProperty.integer({String? description})
      : this._(type: 'integer', description: description);

  const SchemaProperty.boolean({String? description})
      : this._(type: 'boolean', description: description);

  const SchemaProperty.array({String? description, required SchemaProperty items})
      : this._(type: 'array', description: description, items: items);

  const SchemaProperty.object({
    String? description,
    required Map<String, SchemaProperty> properties,
    List<String>? required,
  }) : this._(type: 'object', description: description, properties: properties, required: required);

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
```

- [ ] **Step 2: Write SchemaBuilder**

File: `lib/src/tools/schema_builder.dart`

```dart
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
```

- [ ] **Step 3: Write tests**

File: `test/tools/schema_builder_test.dart`

```dart
import 'package:claudio/src/tools/schema_builder.dart';
import 'package:claudio/src/tools/schema_property.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaProperty', () {
    test('string property', () {
      final p = SchemaProperty.string(description: 'A string', enumValues: ['a', 'b']);
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
```

- [ ] **Step 4: Run tests**

```bash
dart test test/tools/schema_builder_test.dart
```

Expected: 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/tools/ test/tools/
git commit -m "feat: add SchemaProperty and SchemaBuilder"
```

---

### Task 6: Tool + ToolChoice

**Files:**
- Create: `lib/src/tools/tool.dart`
- Create: `lib/src/tools/tool_choice.dart`
- Create: `test/tools/tool_test.dart`

- [ ] **Step 1: Write Tool**

File: `lib/src/tools/tool.dart`

```dart
/// A tool that the model can call.
class Tool {
  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;

  const Tool({
    required this.name,
    this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'input_schema': inputSchema,
  };
}
```

- [ ] **Step 2: Write ToolChoice**

File: `lib/src/tools/tool_choice.dart`

```dart
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
```

- [ ] **Step 3: Write tests**

File: `test/tools/tool_test.dart`

```dart
import 'package:claudio/src/tools/tool.dart';
import 'package:claudio/src/tools/tool_choice.dart';
import 'package:test/test.dart';

void main() {
  group('Tool', () {
    test('toJson with description', () {
      final tool = Tool(name: 'get_weather', description: 'Get weather', inputSchema: {'type': 'object'});
      final json = tool.toJson();
      expect(json['name'], 'get_weather');
      expect(json['description'], 'Get weather');
      expect(json['input_schema'], isA<Map>());
    });

    test('toJson without description', () {
      final tool = Tool(name: 'my_tool', inputSchema: {});
      expect(tool.toJson().containsKey('description'), false);
    });
  });

  group('ToolChoice', () {
    test('auto', () {
      expect(const ToolChoiceAuto().toJson(), {'type': 'auto'});
    });
    test('any', () {
      expect(const ToolChoiceAny().toJson(), {'type': 'any'});
    });
    test('specific tool', () {
      final tc = ToolChoiceSpecific('my_tool');
      expect(tc.toJson(), {'type': 'tool', 'name': 'my_tool'});
      expect(tc.name, 'my_tool');
    });
    test('none', () {
      expect(const ToolChoiceNone().toJson(), {'type': 'none'});
    });
  });
}
```

- [ ] **Step 4: Run tests**

```bash
dart test test/tools/tool_test.dart
```

Expected: 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/tools/tool.dart lib/src/tools/tool_choice.dart test/tools/tool_test.dart
git commit -m "feat: add Tool and ToolChoice types"
```

---

### Task 7: MessageParam + CreateMessageRequest + ThinkingConfig

**Files:**
- Create: `lib/src/messages/message_param.dart`
- Create: `lib/src/messages/create_request.dart`
- Create: `test/messages/create_request_test.dart`

- [ ] **Step 1: Write MessageParam**

File: `lib/src/messages/message_param.dart`

```dart
import 'content_block.dart';

/// A message in a conversation.
class MessageParam {
  final String role;
  final dynamic content; // String or List<ContentBlock>

  const MessageParam({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    if (content is String) {
      return {'role': role, 'content': content as String};
    }
    return {
      'role': role,
      'content': (content as List).map((b) => (b as ContentBlock).toJson()).toList(),
    };
  }
}
```

- [ ] **Step 2: Write CreateMessageRequest + ThinkingConfig**

File: `lib/src/messages/create_request.dart`

```dart
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

  /// Returns a copy with [stream] set to true for streaming requests.
  Map<String, dynamic> toStreamJson() {
    final map = toJson();
    map['stream'] = true;
    return map;
  }
}
```

- [ ] **Step 3: Write tests**

File: `test/messages/create_request_test.dart`

```dart
import 'package:claudio/src/messages/create_request.dart';
import 'package:claudio/src/messages/message_param.dart';
import 'package:claudio/src/tools/tool.dart';
import 'package:claudio/src/tools/tool_choice.dart';
import 'package:test/test.dart';

void main() {
  group('ThinkingConfig', () {
    test('enabled with default budget', () {
      final config = ThinkingConfig.enabled();
      expect(config.type, 'enabled');
      expect(config.budgetTokens, 1024);
    });

    test('disabled', () {
      final config = ThinkingConfig.disabled();
      expect(config.type, 'disabled');
      expect(config.budgetTokens, isNull);
    });

    test('auto', () {
      expect(ThinkingConfig.auto().type, 'auto');
    });

    test('toJson excludes null budgetTokens', () {
      expect(ThinkingConfig.disabled().toJson(), {'type': 'disabled'});
    });
  });

  group('CreateMessageRequest', () {
    test('minimal toJson', () {
      final request = CreateMessageRequest(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1024,
        messages: [MessageParam(role: 'user', content: 'Hi')],
      );
      final json = request.toJson();
      expect(json['model'], 'claude-sonnet-4-20250514');
      expect(json['max_tokens'], 1024);
      expect(json['stream'], false);
    });

    test('with system prompt', () {
      final request = CreateMessageRequest(
        model: 'test', maxTokens: 100, messages: [],
        systemPrompt: 'Be helpful.',
      );
      expect(request.toJson()['system'], 'Be helpful.');
    });

    test('with tools and toolChoice', () {
      final request = CreateMessageRequest(
        model: 'test', maxTokens: 100, messages: [],
        tools: [Tool(name: 'my_tool', inputSchema: {})],
        toolChoice: const ToolChoiceAuto(),
      );
      final json = request.toJson();
      expect(json['tools'], isA<List>());
      expect(json['tool_choice'], {'type': 'auto'});
    });

    test('toStreamJson sets stream to true', () {
      final request = CreateMessageRequest(model: 'test', maxTokens: 100, messages: []);
      expect(request.toStreamJson()['stream'], true);
      expect(request.toJson()['stream'], false);
    });
  });
}
```

- [ ] **Step 4: Run tests**

```bash
dart test test/messages/create_request_test.dart
```

Expected: 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/messages/message_param.dart lib/src/messages/create_request.dart test/messages/create_request_test.dart
git commit -m "feat: add MessageParam, CreateMessageRequest, and ThinkingConfig"
```

---

### Task 8: Message Response Model

**Files:**
- Create: `lib/src/messages/message_response.dart`
- Create: `test/messages/message_response_test.dart`

- [ ] **Step 1: Write Message + Usage models**

File: `lib/src/messages/message_response.dart`

```dart
import 'content_block.dart';
import 'message_param.dart';

/// Token usage information.
class Usage {
  final int inputTokens;
  final int outputTokens;

  const Usage({required this.inputTokens, required this.outputTokens});

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      inputTokens: json['input_tokens'] as int,
      outputTokens: json['output_tokens'] as int,
    );
  }
}

/// Full message response from the API.
class Message {
  final String id;
  final String model;
  final String stopReason;
  final String? stopSequence;
  final Usage usage;
  final List<ContentBlock> content;

  const Message({
    required this.id,
    required this.model,
    required this.stopReason,
    this.stopSequence,
    required this.usage,
    required this.content,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final contentList = (json['content'] as List)
        .map((c) => _parseContentBlock(c as Map<String, dynamic>))
        .toList();

    return Message(
      id: json['id'] as String,
      model: json['model'] as String,
      stopReason: json['stop_reason'] as String,
      stopSequence: json['stop_sequence'] as String?,
      usage: Usage.fromJson(json['usage'] as Map<String, dynamic>),
      content: contentList,
    );
  }

  static ContentBlock _parseContentBlock(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'text' => TextBlock.fromJson(json),
      'tool_use' => ToolUseBlock.fromJson(json),
      'thinking' => ThinkingBlock.fromJson(json),
      _ => TextBlock(text: json.toString()),
    };
  }

  /// Convenience: get all text content concatenated.
  String get text => content.whereType<TextBlock>().map((b) => b.text).join('\n');

  /// Convenience: check if response has tool use requests.
  bool get hasToolUse => content.any((b) => b is ToolUseBlock);

  /// Convenience: get all tool use blocks.
  List<ToolUseBlock> get toolUseBlocks => content.whereType<ToolUseBlock>().toList();

  /// Convert this message to an assistant MessageParam for conversation continuation.
  MessageParam toAssistantParam() {
    return MessageParam(role: 'assistant', content: content);
  }
}
```

- [ ] **Step 2: Write tests**

File: `test/messages/message_response_test.dart`

```dart
import 'package:claudio/src/messages/content_block.dart';
import 'package:claudio/src/messages/message_response.dart';
import 'package:test/test.dart';

void main() {
  group('Usage', () {
    test('fromJson', () {
      final usage = Usage.fromJson({'input_tokens': 10, 'output_tokens': 20});
      expect(usage.inputTokens, 10);
      expect(usage.outputTokens, 20);
    });
  });

  group('Message', () {
    test('fromJson with text content', () {
      final json = {
        'id': 'msg_123',
        'model': 'claude-sonnet-4-20250514',
        'stop_reason': 'end_turn',
        'usage': {'input_tokens': 10, 'output_tokens': 20},
        'content': [{'type': 'text', 'text': 'Hello!'}],
      };
      final msg = Message.fromJson(json);
      expect(msg.id, 'msg_123');
      expect(msg.stopReason, 'end_turn');
      expect(msg.text, 'Hello!');
      expect(msg.hasToolUse, false);
      expect(msg.toolUseBlocks, isEmpty);
    });

    test('fromJson with tool_use', () {
      final json = {
        'id': 'msg_456',
        'model': 'claude-sonnet-4-20250514',
        'stop_reason': 'tool_use',
        'usage': {'input_tokens': 5, 'output_tokens': 15},
        'content': [
          {'type': 'tool_use', 'id': 'toolu_01', 'name': 'get_weather', 'input': {'city': 'Tokyo'}},
        ],
      };
      final msg = Message.fromJson(json);
      expect(msg.hasToolUse, true);
      expect(msg.toolUseBlocks, hasLength(1));
      expect(msg.toolUseBlocks.first.name, 'get_weather');
    });

    test('text getter concatenates multiple TextBlocks', () {
      final json = {
        'id': 'msg', 'model': 'test', 'stop_reason': 'end_turn',
        'usage': {'input_tokens': 1, 'output_tokens': 2},
        'content': [
          {'type': 'text', 'text': 'Hello'},
          {'type': 'text', 'text': 'World'},
        ],
      };
      expect(Message.fromJson(json).text, 'Hello\nWorld');
    });

    test('toAssistantParam', () {
      final json = {
        'id': 'msg', 'model': 'test', 'stop_reason': 'end_turn',
        'usage': {'input_tokens': 1, 'output_tokens': 1},
        'content': [{'type': 'text', 'text': 'Hi'}],
      };
      final param = Message.fromJson(json).toAssistantParam();
      expect(param.role, 'assistant');
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
dart test test/messages/message_response_test.dart
```

Expected: 5 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/src/messages/message_response.dart test/messages/message_response_test.dart
git commit -m "feat: add Message response model with Usage and helpers"
```

---

### Task 9: ProviderAdapter + Anthropic + DeepSeek Adapters

**Files:**
- Create: `lib/src/providers/provider_adapter.dart`
- Create: `lib/src/providers/anthropic_adapter.dart`
- Create: `lib/src/providers/deepseek_adapter.dart`
- Create: `test/providers/provider_adapter_test.dart`

- [ ] **Step 1: Write ProviderAdapter**

File: `lib/src/providers/provider_adapter.dart`

```dart
import '../client/feature.dart';
import '../client/provider.dart';
import '../messages/create_request.dart';
import '../errors/unsupported_feature_exception.dart';

/// Abstract adapter that each provider must implement.
abstract class ProviderAdapter {
  Provider get provider;
  String get baseUrl;
  Set<Feature> get supportedFeatures;

  Map<String, String> buildHeaders(String apiKey);
  Uri buildUri(String path);

  void validateRequest(CreateMessageRequest request) {
    if (request.thinking != null &&
        request.thinking!.type == 'enabled' &&
        !supportedFeatures.contains(Feature.extendedThinking)) {
      throw UnsupportedFeatureException(
        feature: Feature.extendedThinking,
        provider: provider,
      );
    }
  }
}
```

- [ ] **Step 2: Write AnthropicAdapter**

File: `lib/src/providers/anthropic_adapter.dart`

```dart
import '../client/feature.dart';
import '../client/provider.dart';
import 'provider_adapter.dart';

class AnthropicAdapter extends ProviderAdapter {
  @override
  Provider get provider => Provider.anthropic;

  @override
  String get baseUrl => 'https://api.anthropic.com';

  @override
  Set<Feature> get supportedFeatures => {
    Feature.extendedThinking, Feature.imageInput, Feature.toolUse,
    Feature.streaming, Feature.systemPrompt, Feature.promptCaching,
  };

  @override
  Map<String, String> buildHeaders(String apiKey) => {
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  };

  @override
  Uri buildUri(String path) => Uri.parse('$baseUrl$path');
}
```

- [ ] **Step 3: Write DeepSeekAdapter**

File: `lib/src/providers/deepseek_adapter.dart`

```dart
import '../client/feature.dart';
import '../client/provider.dart';
import 'provider_adapter.dart';

class DeepSeekAdapter extends ProviderAdapter {
  @override
  Provider get provider => Provider.deepseek;

  @override
  String get baseUrl => 'https://api.deepseek.com';

  @override
  Set<Feature> get supportedFeatures => {
    Feature.toolUse, Feature.streaming, Feature.systemPrompt,
  };

  @override
  Map<String, String> buildHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'content-type': 'application/json',
  };

  @override
  Uri buildUri(String path) => Uri.parse('$baseUrl$path');
}
```

- [ ] **Step 4: Write tests**

File: `test/providers/provider_adapter_test.dart`

```dart
import 'package:claudio/src/client/feature.dart';
import 'package:claudio/src/client/provider.dart';
import 'package:claudio/src/errors/unsupported_feature_exception.dart';
import 'package:claudio/src/messages/create_request.dart';
import 'package:claudio/src/messages/message_param.dart';
import 'package:claudio/src/providers/anthropic_adapter.dart';
import 'package:claudio/src/providers/deepseek_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicAdapter', () {
    final adapter = AnthropicAdapter();

    test('provider is anthropic', () {
      expect(adapter.provider, Provider.anthropic);
    });

    test('baseUrl', () {
      expect(adapter.baseUrl, 'https://api.anthropic.com');
    });

    test('buildHeaders uses x-api-key', () {
      final headers = adapter.buildHeaders('sk-ant-test');
      expect(headers['x-api-key'], 'sk-ant-test');
      expect(headers['anthropic-version'], '2023-06-01');
      expect(headers['content-type'], 'application/json');
    });

    test('buildUri returns correct URI', () {
      final uri = adapter.buildUri('/v1/messages');
      expect(uri.toString(), 'https://api.anthropic.com/v1/messages');
    });

    test('supports all features', () {
      expect(adapter.supportedFeatures, containsAll([
        Feature.extendedThinking, Feature.imageInput, Feature.toolUse,
        Feature.streaming, Feature.systemPrompt, Feature.promptCaching,
      ]));
    });

    test('validateRequest does not throw for valid request', () {
      final request = CreateMessageRequest(model: 'test', maxTokens: 100, messages: []);
      expect(() => adapter.validateRequest(request), returnsNormally);
    });
  });

  group('DeepSeekAdapter', () {
    final adapter = DeepSeekAdapter();

    test('provider is deepseek', () {
      expect(adapter.provider, Provider.deepseek);
    });

    test('baseUrl', () {
      expect(adapter.baseUrl, 'https://api.deepseek.com');
    });

    test('buildHeaders uses Bearer auth', () {
      final headers = adapter.buildHeaders('sk-deepseek-test');
      expect(headers['Authorization'], 'Bearer sk-deepseek-test');
    });

    test('does NOT support extendedThinking', () {
      expect(adapter.supportedFeatures.contains(Feature.extendedThinking), false);
    });

    test('throws UnsupportedFeatureException for thinking', () {
      final request = CreateMessageRequest(
        model: 'deepseek-chat', maxTokens: 100, messages: [],
        thinking: const ThinkingConfig.enabled(),
      );
      expect(
        () => adapter.validateRequest(request),
        throwsA(isA<UnsupportedFeatureException>()),
      );
    });

    test('supports tool use, streaming, systemPrompt', () {
      expect(adapter.supportedFeatures, containsAll([
        Feature.toolUse, Feature.streaming, Feature.systemPrompt,
      ]));
    });
  });
}
```

- [ ] **Step 5: Run tests**

```bash
dart test test/providers/provider_adapter_test.dart
```

Expected: 12 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/src/providers/ test/providers/
git commit -m "feat: add ProviderAdapter with Anthropic and DeepSeek implementations"
```

---

### Task 10: HTTP Client with Retry

**Files:**
- Create: `lib/src/http/http_client.dart`
- Create: `test/http/http_client_test.dart`
- Create: `test/test_helpers.dart`

- [ ] **Step 1: Write test helpers**

File: `test/test_helpers.dart`

```dart
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:claudio/src/providers/provider_adapter.dart';

class MockClient extends Mock implements http.Client {}

class MockProviderAdapter extends Mock implements ProviderAdapter {}
```

- [ ] **Step 2: Write ClaudioHttpClient**

File: `lib/src/http/http_client.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../client/retry_policy.dart';
import '../errors/api_exception.dart';
import '../errors/authentication_exception.dart';
import '../errors/invalid_request_exception.dart';
import '../errors/network_exception.dart';
import '../errors/rate_limit_exception.dart';
import '../providers/provider_adapter.dart';

class ClaudioHttpClient {
  final http.Client _inner;
  final RetryPolicy _retryPolicy;
  final Duration _timeout;

  ClaudioHttpClient({
    required http.Client inner,
    required RetryPolicy retryPolicy,
    required Duration timeout,
  })  : _inner = inner,
        _retryPolicy = retryPolicy,
        _timeout = timeout;

  Future<http.Response> post(
    ProviderAdapter adapter,
    String apiKey,
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = adapter.buildUri(path);
    final headers = adapter.buildHeaders(apiKey);
    final bodyBytes = jsonEncode(body);

    Exception? lastError;

    for (var attempt = 0; attempt <= _retryPolicy.maxRetries; attempt++) {
      try {
        final response = await _inner
            .post(uri, headers: headers, body: bodyBytes)
            .timeout(_timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        final exception = _handleErrorResponse(response);

        if (!_shouldRetry(response.statusCode)) {
          throw exception;
        }

        lastError = exception;
      } on http.ClientException catch (e) {
        lastError = NetworkException(e.message);
      } on TimeoutException {
        lastError = const NetworkException('Request timed out');
      }

      if (attempt < _retryPolicy.maxRetries) {
        await Future.delayed(_retryPolicy.delayForAttempt(attempt));
      }
    }

    throw lastError!;
  }

  bool _shouldRetry(int statusCode) => statusCode == 429 || statusCode >= 500;

  Exception _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;
    String? requestId;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        requestId = decoded['request_id'] as String?;
      }
    } catch (_) {}

    return switch (statusCode) {
      401 => AuthenticationException(body, statusCode: statusCode, requestId: requestId),
      429 => RateLimitException(body, statusCode: statusCode, requestId: requestId,
          retryAfter: _parseRetryAfter(response.headers['retry-after'])),
      400 => InvalidRequestException(body, statusCode: statusCode, requestId: requestId),
      _ => ApiException(body, statusCode: statusCode, requestId: requestId),
    };
  }

  Duration? _parseRetryAfter(String? value) {
    if (value == null) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) return Duration(seconds: seconds);
    return null;
  }

  void close() => _inner.close();
}
```

- [ ] **Step 3: Write tests**

File: `test/http/http_client_test.dart`

```dart
import 'package:claudio/src/client/retry_policy.dart';
import 'package:claudio/src/errors/authentication_exception.dart';
import 'package:claudio/src/http/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  group('ClaudioHttpClient', () {
    late MockClient mockHttp;
    late ClaudioHttpClient claudioHttp;
    late MockProviderAdapter adapter;

    setUp(() {
      mockHttp = MockClient();
      adapter = MockProviderAdapter();
      when(adapter.buildUri(any)).thenReturn(Uri.parse('https://api.test.com/v1/messages'));
      when(adapter.buildHeaders(any)).thenReturn({'authorization': 'Bearer test'});

      claudioHttp = ClaudioHttpClient(
        inner: mockHttp,
        retryPolicy: const RetryPolicy(maxRetries: 1, initialDelay: Duration(milliseconds: 10)),
        timeout: const Duration(seconds: 5),
      );
    });

    test('successful response returns http.Response', () async {
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('{"id":"ok"}', 200));
      final response = await claudioHttp.post(adapter, 'key', '/v1/messages', {'test': true});
      expect(response.statusCode, 200);
      expect(response.body, '{"id":"ok"}');
    });

    test('throws AuthenticationException on 401', () async {
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));
      expect(
        () => claudioHttp.post(adapter, 'key', '/v1/messages', {}),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('retries on 429 then succeeds', () async {
      var calls = 0;
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async {
        calls++;
        if (calls == 1) return http.Response('Rate limited', 429);
        return http.Response('{"id":"ok"}', 200);
      });
      final response = await claudioHttp.post(adapter, 'key', '/v1/messages', {});
      expect(response.statusCode, 200);
      expect(calls, 2);
    });

    tearDown(() {
      claudioHttp.close();
    });
  });
}
```

- [ ] **Step 4: Run tests**

```bash
dart test test/http/http_client_test.dart
```

Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/http/ test/http/ test/test_helpers.dart
git commit -m "feat: add HTTP client with retry logic"
```

---

### Task 11: SSE Decoder + Stream Events

**Files:**
- Create: `lib/src/streaming/stream_events.dart`
- Create: `lib/src/streaming/sse_decoder.dart`
- Create: `test/streaming/sse_decoder_test.dart`

- [ ] **Step 1: Write stream event types**

File: `lib/src/streaming/stream_events.dart`

```dart
import '../messages/message_response.dart';

/// Base sealed class for all SSE stream events.
sealed class MessageStreamEvent {
  const MessageStreamEvent();
}

/// Stream has started. Contains initial message metadata.
class MessageStartEvent extends MessageStreamEvent {
  final Message message;
  const MessageStartEvent({required this.message});
}

/// An incremental content delta from the stream.
sealed class ContentDelta {
  const ContentDelta();
}

class TextDelta extends ContentDelta {
  final String text;
  const TextDelta({required this.text});
}

class InputJsonDelta extends ContentDelta {
  final String partialJson;
  const InputJsonDelta({required this.partialJson});
}

class ThinkingDelta extends ContentDelta {
  final String thinking;
  const ThinkingDelta({required this.thinking});
}

class ContentBlockDeltaEvent extends MessageStreamEvent {
  final int index;
  final ContentDelta delta;
  const ContentBlockDeltaEvent({required this.index, required this.delta});
}

class StreamStopDelta {
  final String stopReason;
  final String? stopSequence;
  const StreamStopDelta({required this.stopReason, this.stopSequence});
}

class UsageDelta {
  final int outputTokens;
  const UsageDelta({required this.outputTokens});
}

class MessageDeltaEvent extends MessageStreamEvent {
  final StreamStopDelta delta;
  final UsageDelta usage;
  const MessageDeltaEvent({required this.delta, required this.usage});
}

class MessageStopEvent extends MessageStreamEvent {
  const MessageStopEvent();
}
```

- [ ] **Step 2: Write SSE decoder**

File: `lib/src/streaming/sse_decoder.dart`

```dart
import 'dart:async';
import 'dart:convert';

class SseDecoder {
  final Stream<String> _lines;

  SseDecoder(Stream<List<int>> byteStream)
      : _lines = byteStream.transform(utf8.decoder).transform(const LineSplitter());

  Stream<String> get events => _lines.map((line) {
    if (line.startsWith('data: ')) {
      return line.substring(6);
    }
    return '';
  }).where((data) => data.isNotEmpty && data != '[DONE]');
}
```

- [ ] **Step 3: Write tests**

File: `test/streaming/sse_decoder_test.dart`

```dart
import 'dart:convert';
import 'package:claudio/src/streaming/sse_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('SseDecoder', () {
    test('parses data lines and ignores [DONE]', () async {
      final input = Stream.fromIterable([
        utf8.encode('event: message_start\ndata: {"type":"start"}\n\n'),
        utf8.encode('data: {"type":"delta"}\n\n'),
        utf8.encode('data: [DONE]\n\n'),
      ]);
      final decoder = SseDecoder(input);
      final events = await decoder.events.toList();
      expect(events, ['{"type":"start"}', '{"type":"delta"}']);
    });

    test('handles empty input', () async {
      final input = Stream<List<int>>.fromIterable([]);
      final decoder = SseDecoder(input);
      final events = await decoder.events.toList();
      expect(events, isEmpty);
    });

    test('ignores comments and empty data', () async {
      final input = Stream.fromIterable([
        utf8.encode('data: \n\n'),
        utf8.encode(':comment\n\n'),
        utf8.encode('data: {"real":"data"}\n\n'),
      ]);
      final decoder = SseDecoder(input);
      final events = await decoder.events.toList();
      expect(events, ['{"real":"data"}']);
    });
  });
}
```

- [ ] **Step 4: Run tests**

```bash
dart test test/streaming/sse_decoder_test.dart
```

Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/streaming/ test/streaming/
git commit -m "feat: add SSE decoder and stream event types"
```

---

### Task 12: MessagesApi (create + createStream)

**Files:**
- Create: `lib/src/messages/messages_api.dart`
- Create: `test/messages/messages_api_test.dart`

- [ ] **Step 1: Write MessagesApi**

File: `lib/src/messages/messages_api.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'create_request.dart';
import 'message_response.dart';
import '../errors/claudio_exception.dart';
import '../errors/stream_exception.dart';
import '../http/http_client.dart';
import '../providers/provider_adapter.dart';
import '../streaming/sse_decoder.dart';
import '../streaming/stream_events.dart';

class MessagesApi {
  final ClaudioHttpClient _httpClient;
  final ProviderAdapter _adapter;
  final String _apiKey;

  MessagesApi({
    required ClaudioHttpClient httpClient,
    required ProviderAdapter adapter,
    required String apiKey,
  })  : _httpClient = httpClient,
        _adapter = adapter,
        _apiKey = apiKey;

  Future<Message> create(CreateMessageRequest request) async {
    _adapter.validateRequest(request);

    final response = await _httpClient.post(
      _adapter,
      _apiKey,
      '/v1/messages',
      request.toJson(),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Message.fromJson(json);
  }

  Stream<MessageStreamEvent> createStream(CreateMessageRequest request) async* {
    _adapter.validateRequest(request);

    final uri = _adapter.buildUri('/v1/messages');
    final headers = _adapter.buildHeaders(_apiKey);
    final body = jsonEncode(request.toStreamJson());

    final client = http.Client();
    try {
      final streamedRequest = http.Request('POST', uri);
      headers.forEach((k, v) => streamedRequest.headers[k] = v);
      streamedRequest.body = body;

      final streamedResponse = await client.send(streamedRequest);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.transform(utf8.decoder).join();
        throw StreamException(
          'Stream connection failed (${streamedResponse.statusCode}): $errorBody',
        );
      }

      final decoder = SseDecoder(streamedResponse.stream);
      await for (final eventJson in decoder.events) {
        final json = jsonDecode(eventJson) as Map<String, dynamic>;
        final event = _parseStreamEvent(json);
        if (event != null) yield event;
      }

      yield const MessageStopEvent();
    } on ClaudioException {
      rethrow;
    } catch (e) {
      throw StreamException('Stream error: $e');
    } finally {
      client.close();
    }
  }

  MessageStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    return switch (json['type'] as String?) {
      'message_start' => MessageStartEvent(
          message: Message.fromJson(json['message'] as Map<String, dynamic>)),
      'content_block_delta' => _parseContentBlockDelta(json),
      'message_delta' => MessageDeltaEvent(
          delta: StreamStopDelta(
            stopReason: (json['delta'] as Map)['stop_reason'] as String,
            stopSequence: (json['delta'] as Map)['stop_sequence'] as String?,
          ),
          usage: UsageDelta(
            outputTokens: (json['usage'] as Map)['output_tokens'] as int,
          ),
        ),
      'message_stop' => const MessageStopEvent(),
      _ => null,
    };
  }

  ContentBlockDeltaEvent _parseContentBlockDelta(Map<String, dynamic> json) {
    final index = json['index'] as int;
    final delta = json['delta'] as Map<String, dynamic>;
    final deltaType = delta['type'] as String;

    final contentDelta = switch (deltaType) {
      'text_delta' => TextDelta(text: delta['text'] as String),
      'input_json_delta' => InputJsonDelta(partialJson: delta['partial_json'] as String),
      'thinking_delta' => ThinkingDelta(thinking: delta['thinking'] as String),
      _ => throw StreamException('Unknown delta type: $deltaType'),
    };

    return ContentBlockDeltaEvent(index: index, delta: contentDelta);
  }
}
```

- [ ] **Step 2: Write tests**

File: `test/messages/messages_api_test.dart`

```dart
import 'dart:convert';
import 'package:claudio/src/client/retry_policy.dart';
import 'package:claudio/src/errors/authentication_exception.dart';
import 'package:claudio/src/http/http_client.dart';
import 'package:claudio/src/messages/create_request.dart';
import 'package:claudio/src/messages/message_param.dart';
import 'package:claudio/src/messages/messages_api.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  group('MessagesApi.create', () {
    late MockClient mockHttp;
    late ClaudioHttpClient claudioHttp;
    late MockProviderAdapter adapter;
    late MessagesApi api;

    setUp(() {
      mockHttp = MockClient();
      adapter = MockProviderAdapter();
      when(adapter.buildUri(any)).thenReturn(Uri.parse('https://api.test.com/v1/messages'));
      when(adapter.buildHeaders(any)).thenReturn({'x-api-key': 'test-key', 'content-type': 'application/json'});

      claudioHttp = ClaudioHttpClient(
        inner: mockHttp,
        retryPolicy: const RetryPolicy(maxRetries: 0),
        timeout: const Duration(seconds: 5),
      );

      api = MessagesApi(httpClient: claudioHttp, adapter: adapter, apiKey: 'test-key');
    });

    test('returns Message on success', () async {
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(jsonEncode({
            'id': 'msg_123', 'model': 'test-model', 'stop_reason': 'end_turn',
            'usage': {'input_tokens': 10, 'output_tokens': 20},
            'content': [{'type': 'text', 'text': 'Hello!'}],
          }), 200));

      final request = CreateMessageRequest(
        model: 'test-model', maxTokens: 100,
        messages: [MessageParam(role: 'user', content: 'Hi')],
      );

      final message = await api.create(request);
      expect(message.id, 'msg_123');
      expect(message.text, 'Hello!');
    });

    test('throws on error response', () async {
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));

      final request = CreateMessageRequest(model: 'test', maxTokens: 100, messages: []);
      expect(() => api.create(request), throwsA(isA<AuthenticationException>()));
    });

    tearDown(() {
      claudioHttp.close();
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
dart test test/messages/messages_api_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/src/messages/messages_api.dart test/messages/messages_api_test.dart
git commit -m "feat: add MessagesApi with create() and createStream()"
```

---

### Task 13: ClaudioClient — Wiring Everything

**Files:**
- Create: `lib/src/client/claudio_client.dart`
- Create: `test/client/claudio_client_test.dart`

- [ ] **Step 1: Write ClaudioClient**

File: `lib/src/client/claudio_client.dart`

```dart
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'provider.dart';
import 'retry_policy.dart';
import '../errors/client_closed_exception.dart';
import '../http/http_client.dart';
import '../messages/messages_api.dart';
import '../providers/anthropic_adapter.dart';
import '../providers/deepseek_adapter.dart';
import '../providers/provider_adapter.dart';

/// Main entry point for the claudio SDK.
class ClaudioClient {
  final String _apiKey;
  final Provider _provider;
  final Duration _timeout;
  final RetryPolicy _retryPolicy;
  late final ProviderAdapter _adapter;
  late final ClaudioHttpClient _httpClient;
  late final MessagesApi _messages;
  bool _closed = false;

  ClaudioClient({
    required String apiKey,
    required Provider provider,
    Duration timeout = const Duration(seconds: 120),
    RetryPolicy retryPolicy = const RetryPolicy(),
  })  : _apiKey = apiKey,
        _provider = provider,
        _timeout = timeout,
        _retryPolicy = retryPolicy {
    _adapter = _createAdapter(provider);
    _httpClient = ClaudioHttpClient(
      inner: http.Client(),
      retryPolicy: _retryPolicy,
      timeout: _timeout,
    );
    _messages = MessagesApi(
      httpClient: _httpClient,
      adapter: _adapter,
      apiKey: _apiKey,
    );
  }

  factory ClaudioClient.fromEnvironment() {
    final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ??
        Platform.environment['DEEPSEEK_API_KEY'] ??
        Platform.environment['API_KEY'] ??
        '';
    if (apiKey.isEmpty) {
      throw ArgumentError(
        'No API key found. Set ANTHROPIC_API_KEY, DEEPSEEK_API_KEY, or API_KEY.',
      );
    }

    final providerStr = Platform.environment['CLOUD_PROVIDER'] ?? 'anthropic';
    final provider = Provider.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => Provider.anthropic,
    );

    return ClaudioClient(apiKey: apiKey, provider: provider);
  }

  ProviderAdapter _createAdapter(Provider provider) {
    return switch (provider) {
      Provider.anthropic => AnthropicAdapter(),
      Provider.deepseek => DeepSeekAdapter(),
    };
  }

  MessagesApi get messages {
    _checkClosed();
    return _messages;
  }

  Provider get provider => _provider;

  void close() {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }

  void _checkClosed() {
    if (_closed) throw const ClientClosedException();
  }
}
```

- [ ] **Step 2: Write tests**

File: `test/client/claudio_client_test.dart`

```dart
import 'package:claudio/src/client/claudio_client.dart';
import 'package:claudio/src/client/provider.dart';
import 'package:claudio/src/client/retry_policy.dart';
import 'package:claudio/src/errors/client_closed_exception.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudioClient', () {
    test('creates with required params', () {
      final client = ClaudioClient(apiKey: 'sk-test', provider: Provider.anthropic);
      expect(client.provider, Provider.anthropic);
      client.close();
    });

    test('creates with custom retry policy', () {
      final client = ClaudioClient(
        apiKey: 'sk-test',
        provider: Provider.deepseek,
        timeout: const Duration(seconds: 30),
        retryPolicy: const RetryPolicy(maxRetries: 5),
      );
      expect(client.provider, Provider.deepseek);
      client.close();
    });

    test('throws ClientClosedException after close', () {
      final client = ClaudioClient(apiKey: 'sk-test', provider: Provider.anthropic);
      client.close();
      expect(() => client.messages, throwsA(isA<ClientClosedException>()));
    });

    test('provider returns correct value', () {
      final client = ClaudioClient(apiKey: 'sk-test', provider: Provider.deepseek);
      expect(client.provider, Provider.deepseek);
      client.close();
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
dart test test/client/claudio_client_test.dart
```

Expected: 4 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/src/client/claudio_client.dart test/client/claudio_client_test.dart
git commit -m "feat: add ClaudioClient main entry point"
```

---

### Task 14: Helpers + Pub Barrel Export

**Files:**
- Modify: `lib/claudio.dart` (full barrel)
- Create: `lib/src/messages/helpers.dart`
- Create: `test/messages/helpers_test.dart`

- [ ] **Step 1: Write helper functions**

File: `lib/src/messages/helpers.dart`

```dart
import 'content_block.dart';
import 'message_param.dart';

/// Create a tool result block from tool use ID and text.
ToolResultBlock createToolResult({required String toolUseId, required String text}) {
  return ToolResultBlock(toolUseId: toolUseId, content: text);
}

/// Wraps tool results in a user MessageParam for conversation continuation.
MessageParam createToolResultMessage(List<ToolResultBlock> toolResults) {
  return MessageParam(role: 'user', content: toolResults);
}
```

- [ ] **Step 2: Write tests**

File: `test/messages/helpers_test.dart`

```dart
import 'package:claudio/src/messages/content_block.dart';
import 'package:claudio/src/messages/helpers.dart';
import 'package:claudio/src/messages/message_param.dart';
import 'package:test/test.dart';

void main() {
  group('createToolResult', () {
    test('creates ToolResultBlock with toolUseId and text', () {
      final result = createToolResult(toolUseId: 'toolu_01', text: 'Sunny, 30C');
      expect(result.toolUseId, 'toolu_01');
      expect(result.content, 'Sunny, 30C');
    });
  });

  group('createToolResultMessage', () {
    test('wraps tool results in user MessageParam', () {
      final results = [
        ToolResultBlock(toolUseId: 'toolu_01', content: 'Result 1'),
        ToolResultBlock(toolUseId: 'toolu_02', content: 'Result 2'),
      ];
      final param = createToolResultMessage(results);
      expect(param.role, 'user');
      expect(param.content, results);
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
dart test test/messages/helpers_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 4: Write barrel export**

File: `lib/claudio.dart`

```dart
/// claudio — Multi-provider AI SDK for Dart/Flutter.
library claudio;

// Client
export 'src/client/claudio_client.dart';
export 'src/client/provider.dart';
export 'src/client/retry_policy.dart';

// Messages
export 'src/messages/create_request.dart';
export 'src/messages/message_param.dart';
export 'src/messages/message_response.dart';
export 'src/messages/content_block.dart';
export 'src/messages/helpers.dart';

// Tools
export 'src/tools/tool.dart';
export 'src/tools/tool_choice.dart';
export 'src/tools/schema_builder.dart';
export 'src/tools/schema_property.dart';

// Streaming
export 'src/streaming/stream_events.dart';
export 'src/streaming/sse_decoder.dart';

// Errors
export 'src/errors/claudio_exception.dart';
export 'src/errors/authentication_exception.dart';
export 'src/errors/rate_limit_exception.dart';
export 'src/errors/invalid_request_exception.dart';
export 'src/errors/api_exception.dart';
export 'src/errors/network_exception.dart';
export 'src/errors/stream_exception.dart';
export 'src/errors/unsupported_feature_exception.dart';
export 'src/errors/client_closed_exception.dart';
```

- [ ] **Step 5: Commit**

```bash
git add lib/claudio.dart lib/src/messages/helpers.dart test/messages/helpers_test.dart
git commit -m "feat: add helpers and pub barrel export"
```

---

### Task 15: Full Test Suite + Lint

- [ ] **Step 1: Run all tests**

```bash
dart test
```

Expected: All tests PASS (approximately 60+ tests).

- [ ] **Step 2: Run Dart analyzer**

```bash
dart analyze
```

Expected: No issues found.

- [ ] **Step 3: Fix any issues and commit**

```bash
git add -A && git commit -m "chore: fix lint and test issues from full suite"
```

---

### Task 16: Example

**Files:**
- Create: `example/main.dart`

- [ ] **Step 1: Write example**

File: `example/main.dart`

```dart
import 'package:claudio/claudio.dart';

void main() async {
  // Anthropic
  final anthropicClient = ClaudioClient(
    apiKey: 'sk-ant-your-api-key',
    provider: Provider.anthropic,
  );

  final message = await anthropicClient.messages.create(
    CreateMessageRequest(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1024,
      messages: [MessageParam(role: 'user', content: 'Hello, Claude!')],
    ),
  );
  print('Anthropic: ${message.text}');
  anthropicClient.close();

  // DeepSeek
  final deepSeekClient = ClaudioClient(
    apiKey: 'sk-deepseek-your-api-key',
    provider: Provider.deepseek,
  );

  final dsMessage = await deepSeekClient.messages.create(
    CreateMessageRequest(
      model: 'deepseek-chat',
      maxTokens: 1024,
      messages: [MessageParam(role: 'user', content: 'Hello!')],
    ),
  );
  print('DeepSeek: ${dsMessage.text}');
  deepSeekClient.close();
}
```

- [ ] **Step 2: Commit**

```bash
git add example/ && git commit -m "docs: add example usage"
```
