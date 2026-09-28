using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketTaskSupervisor
{
    private readonly Func<BridgeEvent, Task> _eventSink;

    public BridgeSocketTaskSupervisor(Func<BridgeEvent, Task> eventSink)
    {
        _eventSink = eventSink ?? throw new ArgumentNullException(nameof(eventSink));
    }

    public async Task RunAsync(Func<Task> operation)
    {
        ArgumentNullException.ThrowIfNull(operation);
        try
        {
            await operation();
        }
        catch (OperationCanceledException)
        {
            // Intentional socket shutdown is not a transport failure.
        }
        catch (Exception error)
        {
            await _eventSink(BridgeEvent.Error("socket_error", error.Message));
        }
    }
}
