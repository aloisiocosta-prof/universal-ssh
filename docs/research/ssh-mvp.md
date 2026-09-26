# SSH MVP — Research Question, Requirements and Experiment Protocol

Issue: #11  
Epic: #10

## Research question
What platform adaptations are required to provide the same observable SSH session capability on Web, Android, and UWP/Xbox, and what measurable limitations or costs does each target introduce?

## Baseline claim
The repository currently demonstrates a reproducible quality/build pipeline for Web, Android, and UWP x64. Build success is not evidence that an end-to-end SSH session works on any target, and Windows UWP x64 execution is not evidence of Xbox compatibility.

## Protocol model
The MVP follows the protocol layering defined by the SSH standards:
1. transport and server authentication;
2. user authentication over the protected transport;
3. connection/session channel for interactive login and I/O.

RFC 4253 defines the transport layer and server authentication. RFC 4252 defines user authentication over that transport. RFC 4254 defines interactive sessions over the authenticated connection.

## Security invariant
A server host key must not be silently trusted. The client must expose an explicit verification policy and a changed/mismatched key must fail closed unless a future, separately specified recovery policy applies.

## Functional requirements
| ID | Requirement | Observable acceptance |
|---|---|---|
| FR-001 | Configure host, port, and username | Values enter a connection request without protocol/UI coupling |
| FR-002 | Establish a transport | Connected or typed failure is observable |
| FR-003 | Perform SSH handshake | Negotiation reaches authenticated transport or typed failure |
| SEC-001 | Verify server host identity | Unknown/changed/mismatched key follows explicit policy; no silent acceptance |
| FR-004 | Authenticate a user | At least one secure method succeeds against the controlled test server |
| FR-005 | Open a session/shell channel | Server confirms channel/session open |
| FR-006 | Exchange terminal I/O | Input reaches server and stdout/stderr return to client |
| FR-007 | Disconnect deterministically | Local/remote close and error states are observable |
| NFR-001 | Keep protocol logic independent of UI | Core tests run without Flutter widget/platform runtime |
| NFR-002 | Preserve platform differences | Transport adapters expose capability/limitation rather than pretending equivalence |

## Initial hypotheses
- H1: the observable SSH session lifecycle can be represented by a platform-neutral domain contract.
- H2: transport realization will require platform-specific adapters.
- H3: successful Windows UWP x64 packaging alone will not establish Xbox runtime compatibility.

These hypotheses remain unconfirmed until measured.

## Variables and measurements
Record, where meaningful: connection outcome, handshake outcome, authentication outcome, session-open outcome, time-to-connect, time-to-first-output, disconnect behavior, artifact SHA/version, platform/runtime version, server configuration, and sanitized failure category. Performance claims require repeated measurements and dispersion; single timings are diagnostic only.

## Controlled experiment
Use a controlled SSH server with a known host key and dedicated non-production credentials/key material. Preserve:
- exact repository commit SHA;
- client/platform/runtime versions;
- server implementation/version and relevant configuration;
- host-key fingerprint expected by the test;
- test command/input and expected output;
- sanitized logs;
- raw measurements;
- pass/fail result and limitation notes.

Never commit private keys, passwords, tokens, or production host material.

## Platform evidence matrix
| Capability | Web | Android | Windows UWP x64 | Xbox One UWP |
|---|---|---|---|---|
| Build/package | measured separately | measured separately | measured separately | N/A until device deployment |
| Transport | experiment required | experiment required | experiment required | experiment required |
| SSH handshake | experiment required | experiment required | experiment required | experiment required |
| Host verification | experiment required | experiment required | experiment required | experiment required |
| Authentication | experiment required | experiment required | experiment required | experiment required |
| Interactive session | experiment required | experiment required | experiment required | experiment required |

## Threats to validity
- CI build success does not imply runtime compatibility.
- A single SSH server implementation does not represent all servers.
- Emulator/desktop results do not substitute for Xbox hardware results.
- Network conditions confound latency measurements.
- A Web transport bridge/proxy, if required, changes the system boundary and must be reported as such.
- Coverage is an indicator, not evidence of protocol correctness or security.

## Traceability
#10 → #11 → #12 → #13 → #14 → #15 → #16 → #17 → #18.

The next step is #12: derive domain contracts and RED tests directly from FR-001..FR-007, SEC-001, NFR-001 and NFR-002.

## Normative protocol references
- RFC 4253 — The Secure Shell (SSH) Transport Layer Protocol.
- RFC 4252 — The Secure Shell (SSH) Authentication Protocol.
- RFC 4254 — The Secure Shell (SSH) Connection Protocol.

Algorithm choices must not be inferred solely from the 2006 baseline RFC requirements; current cryptographic recommendations require a separate evidence review before implementation.
