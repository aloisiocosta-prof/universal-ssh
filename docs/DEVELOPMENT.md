# Versioning and TDD policy

This project follows Semantic Versioning 2.0.0.

- **MAJOR**: incompatible public API or protocol changes.
- **MINOR**: backward-compatible functionality.
- **PATCH**: backward-compatible fixes.
- Before 1.0.0, incompatible changes increment MINOR.
- Git release tags use `vMAJOR.MINOR.PATCH`.
- `pubspec.yaml` is the source of truth for the application version.

## Test-driven development

Production behavior is developed using **Red → Green → Refactor**:

1. Add or change a test that expresses the required behavior and observe it fail.
2. Implement the smallest production change that makes it pass.
3. Refactor while keeping the suite green.

Every platform build depends on the shared **Quality Gate**. The gate covers formatting, static analysis, unit/widget tests, coverage, dependency audit, security patterns, and a performance regression smoke test.

The initial coverage floor is **70%** and should only move upward. Platform-specific tests complement, rather than replace, core tests.
