using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketDataForwarder
{
    private readonly Func<BridgeEvent, Task> _eventSink;

    public BridgeSocketDataForwarder(Func<BridgeEvent, Task> eventSink)
    {
        _eventSink = eventSink ?? throw new ArgumentNullException(nameof(eventSink));
    }

    public Task ForwardAsync(byte[] bytes)
    {
        ArgumentNullException.ThrowIfNull(bytes);
        return _eventSink(BridgeEvent.Data(bytes));
    }
}
