# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-05-14

### Fixed

- Fix README image paths using absolute GitHub URLs for pub.dev rendering
- Fix pub badge, install instructions, and import paths to use `claudio_sdk`

## [0.1.0] - 2026-05-14

### Added

- Initial release of Anthropic SDK Dart.
- `AnthropicClient` with API key and environment variable initialization.
- Messages API support (`create` and `createStream`).
- Multi-tools support with object type schemas and nested properties.
- `SchemaBuilder` fluent API for constructing JSON Schema definitions.
- Streaming response via Server-Sent Events (SSE).
- Extended thinking support (enabled, disabled, adaptive).
- Structured exception hierarchy with `AnthropicException` base class.
- Automatic retry with exponential backoff and jitter for 429 and 5xx errors.
- Full serialization/deserialization layer with forward compatibility.
