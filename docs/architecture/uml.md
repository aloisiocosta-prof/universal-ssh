# UML 2.x catalog in Mermaid

## 1. Class
```mermaid
classDiagram
  BridgeSocket <|.. WinRtBridgeSocket
  WinRtBridgeSocket *-- BridgeSocketLifecycle
  WinRtBridgeSocket *-- BridgeSocketWriteGate
  WinRtBridgeSocket ..> BridgeSocketReadLoop
  WinRtBridgeSocket ..> BridgeSocketCleanup
```

## 2. Object
```mermaid
flowchart LR
  socket["socket: WinRtBridgeSocket"] --> lifecycle["lifecycle: BridgeSocketLifecycle"]
  socket --> writeGate["writeGate: BridgeSocketWriteGate"]
  socket --> stream["socket: StreamSocket"]
  socket --> reader["reader: DataReader"]
  socket --> writer["writer: DataWriter"]
```

## 3. Component
```mermaid
flowchart LR
  Flutter[Flutter Web runtime] --> Bridge[WebView Bridge]
  Bridge --> Controller[UWP Host Controller]
  Controller --> Socket[Native Socket Component]
  Socket --> WinRT[Windows.Networking.Sockets]
```

## 4. Composite Structure
```mermaid
flowchart TB
  subgraph W[WinRtBridgeSocket]
    LC[Lifecycle]
    WG[Write Gate]
    RL[Read Loop]
    CL[Cleanup]
  end
  W --> SS[StreamSocket]
```

## 5. Package
```mermaid
flowchart LR
  Dart["lib/ transport"] --> UWP["uwp/UniversalSshUwp"]
  Tests["uwp/UniversalSshUwp.ProtocolTests"] --> UWP
  UWP --> WinRT["Windows Runtime"]
```

## 6. Deployment
```mermaid
flowchart LR
  subgraph Xbox["Windows/UWP device"]
    WebView[Flutter Web in WebView]
    Native[UWP Native Host]
    WebView --> Native
  end
  Native -->|TCP| SSH[SSH Server]
  CI[GitHub Actions Windows runner] -->|build/test package| Xbox
```

## 7. Profile
```mermaid
flowchart LR
  Secure["«secure-boundary» Bridge parser"] --> Native["«native-adapter» WinRtBridgeSocket"]
  Native --> TCP["«transport» StreamSocket"]
  Test["«protocol-test» Portable harness"] -. validates .-> Native
```

## 8. Use Case
```mermaid
flowchart LR
  User((User)) --> Connect[Connect to SSH host]
  User --> Send[Send terminal input]
  User --> Close[Disconnect]
  Connect --> Verify[Verify host identity]
  Connect --> Auth[Authenticate]
```

## 9. Activity
```mermaid
flowchart TD
  A[Connect request] --> B{TryBeginConnect?}
  B -- no --> X[Reject]
  B -- yes --> C[Open StreamSocket]
  C --> D{success?}
  D -- no --> E[Cleanup and rollback]
  D -- yes --> F[Publish reader/writer]
  F --> G[Emit Connected]
  G --> H[Start read loop]
```

## 10. State Machine
```mermaid
stateDiagram-v2
  [*] --> Disconnected
  Disconnected --> Connecting: TryBeginConnect
  Closed --> Connecting: TryBeginConnect
  Connecting --> Connected: MarkConnected
  Connecting --> Disconnected: MarkConnectFailed
  Connected --> Disconnected: MarkConnectFailed / tail rollback
  Connected --> Closing: TryBeginClose
  Closing --> Closed: MarkClosed
```

## 11. Sequence
```mermaid
sequenceDiagram
  participant W as WebView
  participant H as HostController
  participant S as WinRtBridgeSocket
  participant L as Lifecycle
  participant T as StreamSocket
  W->>H: connect(host, port)
  H->>S: ConnectAsync
  S->>L: TryBeginConnect()
  S->>T: ConnectAsync
  alt success
    S->>L: MarkConnected()
    S-->>W: connected
  else failure
    S->>L: MarkConnectFailed()
    S-->>H: exception
  end
```

## 12. Communication
```mermaid
flowchart LR
  W["1 WebView"] -->|"2 command"| H["HostController"]
  H -->|"3 ConnectAsync"| S["WinRtBridgeSocket"]
  S -->|"4 transition"| L["Lifecycle"]
  S -->|"5 TCP"| T["StreamSocket"]
  S -->|"6 BridgeEvent"| W
```

## 13. Interaction Overview
```mermaid
flowchart TD
  C[Connect interaction] --> Q{Connected?}
  Q -- yes --> IO[Read/write interaction]
  Q -- no --> R[Rollback interaction]
  IO --> D[Disconnect interaction]
  R --> C
```

## 14. Timing
```mermaid
sequenceDiagram
  participant W1 as Write 1
  participant G as WriteGate
  participant C as Close
  W1->>G: acquire
  C->>G: DrainAsync / mark draining
  Note over C,G: close waits while write is active
  W1-->>G: release
  G-->>C: exclusive drain
  C->>C: cleanup resources
  Note over G: later writes rejected until Reset after reconnect
```
