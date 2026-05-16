# Contributing

Thanks for your interest in contributing to `claudio_sdk`.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/claudio.git`
3. Create a branch: `git checkout -b feat/your-feature`
4. Install dependencies: `dart pub get`

## Development

```bash
# Run tests
dart test

# Run static analysis
dart analyze .

# Format code
dart format .

# Generate docs
dart doc .
```

## Commit Convention

- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — code restructuring
- `chore:` — maintenance, deps, config
- `docs:` — documentation
- `test:` — test changes
- `style:` — formatting

## Pull Request Checklist

- [ ] Tests pass: `dart test`
- [ ] Analysis clean: `dart analyze .`
- [ ] Code formatted: `dart format .`
- [ ] Updated CHANGELOG.md if applicable
- [ ] PR targets the `dev` branch

## Code Style

This project follows Dart recommended lints with strict mode. See `analysis_options.yaml`.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
