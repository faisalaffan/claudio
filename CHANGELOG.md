# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.12] - 2026-05-16

### Changed

- Sync README.id.md with README.md: add Docker install and Sponsor section

## [0.1.11] - 2026-05-16

### Fixed

- Fix GHCR Docker build: analyze lib/ only, exclude screenshots from image

## [0.1.10] - 2026-05-16

### Fixed

- Commit pubspec.lock for reproducible builds, fix GHCR Dockerfile COPY failure
- Update LICENSE copyright to 2026 claudio_sdk

## [0.1.9] - 2026-05-16

### Added

- Docker support: Dockerfile, .dockerignore, GHCR publish workflow
- Docker installation instructions in README

## [0.1.8] - 2026-05-16

### Added

- Sponsor section in README with GitHub Sponsors, Ko-fi, and Saweria badges
- Multi-platform funding configuration in .github/FUNDING.yml

## [0.1.7] - 2026-05-16

### Added

- GitHub community health files: SUPPORT.md, SECURITY.md, CODE_OF_CONDUCT.md
- GitHub contribution files: CONTRIBUTING.md, CONTRIBUTORS.md, AUTHORS.md
- GitHub metadata: CODEOWNERS, CITATION.cff, .github/FUNDING.yml, .github/dependabot.yml
- Issue templates: bug report and feature request
- Pull request template

## [0.1.6] - 2026-05-16

### Changed

- Point `documentation` field to GitHub instead of pub.dev

## [0.1.5] - 2026-05-16

### Added

- Pub.dev metadata: `documentation`, `topics`, `screenshots`, and `funding` fields in pubspec.yaml
- Terminal output screenshot (`screenshots/terminal_example.png`)
- Architecture diagram screenshot (`screenshots/architecture.png`)

### Changed

- Format all source files with `dart format`

## [0.1.4] - 2026-05-15

### Fixed

- Remove `build_runner` from dev_dependencies to reduce dependency graph
- Bump `test` lower bound to `^1.29.0` for Dart 3.x compatibility

## [0.1.3] - 2026-05-14

### Added

- Dartdoc comments to all public exception classes, streaming events, and provider adapters

## [0.1.2] - 2026-05-14

### Added

- GitHub Actions CI workflow for automated pub.dev publishing

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
