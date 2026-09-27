# Traceability matrix

| Requirement / work item | Evidence | Issue | Test / verification | Implementation / artifact | PR / checkpoint |
|---|---|---:|---|---|---|
| REQ-QUALITY-001: shared core passes mandatory quality gate before affected platform builds | Engineering policy | #2 | Quality Gate | `.github/workflows/quality.yml`, `.github/workflows/build.yml` | #9 and subsequent green main checkpoints |
| REQ-DEVSECOPS-TRACE: changes carry Issue/PR/check evidence | Development policy | #2, #5 | PR templates + Actions evidence | `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`, `docs/DEVELOPMENT.md` | reconciliation after historical #6 |
| REQ-SECURITY-001: dependency and secret controls fail visibly | DevSecOps policy | #3 | Dependency Review + scheduled audit + Quality Gate | `.github/workflows/security.yml`, `.github/workflows/quality.yml` | reconciliation after historical #7 |
| FR-001..FR-007: minimum SSH domain/session contracts | SSH MVP research specification | #12 | `test/core/ssh/ssh_contracts_test.dart` | `lib/core/ssh/ssh_contracts.dart` | #22 |
| NFR-002: transport capabilities are platform-explicit | SSH MVP research specification | #13 | `test/core/transport/*` | `lib/core/transport/*` | #23-#35 (ongoing #13) |
| UWP-BRIDGE-001: WebView bridge uses typed JSON/Base64 boundary | UWP bridge ADR | #13 | Dart bridge tests + UWP protocol harness | `uwp/UniversalSshUwp/BridgeCommand*.cs`, `lib/core/transport/uwp_bridge_protocol.dart` | #29-#35 |

Update this matrix in the same change that introduces or materially changes a requirement.
A build artifact is evidence only for what that build exercised; UWP x64 packaging does not
establish Xbox hardware compatibility.
