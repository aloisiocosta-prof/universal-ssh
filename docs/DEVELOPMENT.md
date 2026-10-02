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

## GitHub Pages deployment verification

A successful build is not a successful deployment. On every push to `main`, the Build workflow deploys the Pages artifact and then probes the URL returned by the GitHub Pages environment. The probe retries for propagation, requires HTTP success for the page and Flutter bootstrap, and checks the repository base path.

This smoke test proves that the generated static app is reachable at the expected path. It does not prove browser interaction, WSS gateway availability, SSH connectivity, or Windows/Xbox compatibility; those require their own integration and platform evidence. Pull requests build and validate the Pages variant, but do not deploy to the public site.

## Versioned releases and artifacts

The release tag must match the SemVer portion of `pubspec.yaml`: for example, `0.1.0+1` maps to tag `v0.1.0`. The Release workflow rejects a mismatched tag, builds the Pages-compatible Web/PWA bundle from that tagged commit, and publishes a GitHub Release with the versioned ZIP, `SHA256SUMS.txt`, and commit/version metadata. The release build itself runs on the tag; create tags only from a reviewed commit on `main` after required checks pass.

Android and UWP packages remain CI artifacts for testing until release signing is configured. The current Android output is not signed with a project release key, and the UWP package is unsigned; publishing either as a supported installable release would mislead users. Add protected signing keys/certificates as GitHub Actions environment secrets and verify an install on target hardware before promoting those packages to Releases.

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

The Security workflow complements it with GitHub Dependency Review on pull requests and
scheduled dependency/secret audits. Security failures are not intentionally hidden with
`continue-on-error`.

## Pull requests and audit trail

Every material change should reference its Issue/Epic and preserve, when applicable:

```text
Issue -> branch -> commit SHA -> PR -> workflow run -> job/step
-> artifact/evidence -> merge SHA -> release/experiment
```

A PR should identify acceptance criteria, test evidence, security impact and affected
artifacts. TDD changes should preserve evidence of the intended RED and subsequent GREEN.

Logs and large artifacts remain in GitHub Actions/Release according to configured retention;
Git stores policies, source, small reproducible records and traceability metadata.

## Definition of Done

An item is Done only when its acceptance criteria are demonstrated, required checks pass,
the change is integrated, and applicable documentation/evidence is traceable. A successful
Windows UWP build is not evidence of Xbox hardware compatibility; that requires the
platform experiment defined by the SSH MVP research plan.
