using System;
using System.Text.Json;

namespace UniversalSshUwp;

public sealed class BridgeEvent
{
    private readonly object _value;

    private BridgeEvent(object value)
    {
        _value = value;
    }

    public static BridgeEvent Connected() =>
        new(new { type = "connected" });

    public static BridgeEvent Data(byte[] bytes) =>
        new(new { type = "data", payload = Convert.ToBase64String(bytes) });

    public static BridgeEvent Closed() =>
        new(new { type = "closed" });

    public static BridgeEvent Error(string code, string message) =>
        new(new { type = "error", code, message });

    public string ToJson() => JsonSerializer.Serialize(_value);
}
