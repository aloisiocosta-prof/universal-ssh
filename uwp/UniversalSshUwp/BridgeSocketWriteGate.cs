using System;
using System.Threading;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketWriteGate
{
    private readonly SemaphoreSlim _gate = new(1, 1);
    private bool _drained;

    public async Task RunAsync(Func<Task> operation)
    {
        ArgumentNullException.ThrowIfNull(operation);
        await _gate.WaitAsync();
        try
        {
            if (_drained)
            {
                throw new InvalidOperationException("Socket write gate is closed.");
            }

            await operation();
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task DrainAsync(Func<Task> operation)
    {
        ArgumentNullException.ThrowIfNull(operation);
        await _gate.WaitAsync();
        try
        {
            _drained = true;
            await operation();
        }
        finally
        {
            _gate.Release();
        }
    }
}
