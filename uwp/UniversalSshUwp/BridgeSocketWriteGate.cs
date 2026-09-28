using System;
using System.Threading;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketWriteGate
{
    private readonly SemaphoreSlim _gate = new(1, 1);

    public async Task RunAsync(Func<Task> operation)
    {
        ArgumentNullException.ThrowIfNull(operation);
        await _gate.WaitAsync();
        try
        {
            await operation();
        }
        finally
        {
            _gate.Release();
        }
    }
}
