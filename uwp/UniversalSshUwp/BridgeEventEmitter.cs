using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeEventEmitter
{
    private readonly Func<string, Task> _sink;

    public BridgeEventEmitter(Func<string, Task> sink)
    {
        _sink = sink ?? throw new ArgumentNullException(nameof(sink));
    }

    public Task EmitAsync(BridgeEvent bridgeEvent)
    {
        ArgumentNullException.ThrowIfNull(bridgeEvent);
        return _sink(bridgeEvent.ToJson());
    }
}
