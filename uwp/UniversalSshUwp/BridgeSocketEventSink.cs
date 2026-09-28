using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public static class BridgeSocketEventSink
{
    public static Func<BridgeEvent, Task> Require(Func<BridgeEvent, Task>? eventSink) =>
        eventSink ?? throw new InvalidOperationException("Bridge socket EventSink is required before connecting.");
}
