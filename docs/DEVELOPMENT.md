# Development, versioning and TDD policy

## Source of truth and integration flow

GitHub is the auditable source of truth:

```text
Epic/Issue -> short-lived branch -> Conventional Commits -> Pull Request to main
-> affected CI/Security checks -> artifact/evidence -> squash merge -> stable main
```

`main` is the stable integration branch. Functional work must not be committed directly to it.
Branches should be short-lived and scoped to one traceable change. The historical `develop`
flow is not part of the current project workflow.

## Versioning

This project follows Semantic Versioning 2.0.0.

- **MAJOR**: incompatible public API or protocol changes.
- **MINOR**: backward-compatible functionality.
- **PATCH**: backward-compatible fixes.
- Before 1.0.0, incompatible changes increment MINOR.
- Git release tags use `vMAJOR.MINOR.PATCH`.
- `pubspec.yaml` is the source of truth for the application version.

## Test-driven development

Production behavior is developed using **Red -> Green -> Refactor**:

1. Add/change a test expressing the required behavior and observe the intended failure.
2. Implement the smallest production change that makes it pass.
3. Refactor while keeping the relevant gates green.

Formatting is part of the gate; the exact CI formatter command is authoritative.
Platform-specific tests complement, rather than replace, core tests.

## Quality and security gates

The shared Quality Gate covers formatting, static analysis, unit/widget tests, coverage,
dependency audit, secret patterns and a performance smoke test. The initial core coverage
floor is 70%.

The Security workflow runs GitHub Dependency Review on pull requests, OSV Scanner against supported manifests/lockfiles, and scheduled dependency/secret audits. The Quality Gate's `flutter analyze` is Dart/Flutter static analysis; it is not represented as a dedicated Dart SAST engine. Security failures are not intentionally hidden with
`continue-on-error`.

## Pull requests and audit trail

Every material change should reference its Issue/Epic and preserve, when applicable:

```text
Issue -> branch -> commit SHA -> PR -> workflow run -> job/step
-> artifact/evidence -> merge SHA -> release/experiment
```

A PR should identify acceptance criteria, test evidence, security impact and affected
artifacts. TDD changes should preserve evidence of the intended RED and subsequent GREEN.

Release builds are tag-driven in `.github/workflows/release.yml`, validate the tag against `pubspec.yaml`, publish Web and Android artifacts, and attach SHA-256 checksums to the GitHub Release. UWP signing remains unavailable until a signing certificate and protected environment are configured. Logs and large CI artifacts remain in GitHub Actions according to configured retention; Git stores policies, source, small reproducible records and traceability metadata.

## Definition of Done

An item is Done only when its acceptance criteria are demonstrated, required checks pass,
the change is integrated, and applicable documentation/evidence is traceable. A successful
Windows UWP build is not evidence of Xbox hardware compatibility; that requires the
platform experiment defined by the SSH MVP research plan.
