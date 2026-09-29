# Architecture diagrams

Architecture is maintained as executable Mermaid documentation and evolves with production code.

## Merge rule

A GREEN implementation that changes structure, behavior, lifecycle, deployment, dependencies, or runtime boundaries MUST update every affected diagram before merge.

The catalog contains the four C4 abstraction levels and the fourteen UML 2.x diagram types. Mermaid does not provide native notation for every UML type, so the closest semantically faithful Mermaid primitive is used and the mapping is explicit.

- C4: Context, Container, Component, Code.
- UML structural: Class, Object, Component, Composite Structure, Package, Deployment, Profile.
- UML behavioral: Use Case, Activity, State Machine.
- UML interaction: Sequence, Communication, Interaction Overview, Timing.

Current architectural slice: UWP WebView bridge and native socket lifecycle.
