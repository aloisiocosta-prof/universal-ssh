# ADR: UWP WebView bridge for the Flutter Web runtime

## Status

Proposed.

## Context

The Flutter Web runtime embedded by the UWP host cannot open a native TCP socket directly. The shared SSH core therefore depends on a host bridge for the UWP WebView runtime.

Microsoft documents the classic `Windows.UI.Xaml.Controls.WebView` as the WebView that Xbox apps must use. Its script-to-host channel is `window.external.notify(string)`, received by the UWP `ScriptNotify` event. The host can invoke JavaScript through `WebView.InvokeScriptAsync`, whose arguments and return value cross the boundary as strings.

Microsoft also warns that `ScriptNotify` is initiated by external code and should be enabled only for trusted content/URIs. External pages require explicit manifest rules; packaged/local content has different rule requirements.

Microsoft documentation is currently inconsistent about WebView2 on Xbox: current WebView2 documentation lists Xbox support, while Xbox media architecture guidance still states that WebView2 is not supported. This project therefore does not use WebView2 compatibility as evidence for Xbox One 2013.

## Decision

For the Xbox-oriented UWP shell, retain the classic `Windows.UI.Xaml.Controls.WebView` boundary until hardware evidence supports a replacement.

Use a string-only bridge:

- Flutter Web/JavaScript → UWP: serialize `UwpBridgeMessage` as JSON and send it through `window.external.notify`.
- UWP → Flutter Web/JavaScript: serialize `UwpBridgeEvent` as JSON and deliver it through a named JavaScript callback invoked with `InvokeScriptAsync`.
- Binary SSH transport bytes remain Base64 inside the JSON envelope.
- The host accepts bridge messages only from the packaged/trusted Flutter application origin.
- Credentials are not fields of the transport-control envelope.

The existing message vocabulary remains `connect`, `data`, and `close`. The event vocabulary remains `connected`, `data`, `closed`, and `error`.

## Consequences

Base64 introduces encoding and size overhead and must later be measured rather than assumed negligible. JSON provides an inspectable protocol but parsing failures and unknown message types must be handled explicitly.

The decision establishes an interop mechanism; it does not demonstrate Xbox One compatibility, TCP/22 reachability, SSH interoperability, performance, or security. Those require separate implementation tests and the planned Xbox hardware experiment.

## Evidence

- Microsoft Learn: Windows.UI.Xaml.Controls.WebView API reference — Xbox apps must use this WebView.
- Microsoft Learn: WebView.ScriptNotify — `window.external.notify` passes a string to the host and trusted-URI restrictions are required.
- Microsoft Learn: WebView.InvokeScriptAsync — script arguments and return values cross as strings.
- Microsoft Learn: Xbox Media Application Architecture — documents a thin C# app hosting a website in a full-screen WebView and states WebView2 is not yet supported on Xbox.
- Microsoft Learn: current WebView2 overview/sample documentation — lists Xbox support, creating a documentation conflict that must not be treated as Xbox One 2013 hardware evidence.

## Verification plan

1. RED/GREEN test the JavaScript-facing adapter independently from UWP.
2. RED/GREEN test C# parsing/serialization and trusted-origin rejection.
3. Integrate `ScriptNotify` and `InvokeScriptAsync` in the UWP shell.
4. Preserve Web, Android, and UWP build gates.
5. Execute EXP-XBOX-001 on the physical Xbox One 2013 before claiming compatibility.
