using System;
using System.Threading;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketWriteGate
{
    private readonly SemaphoreSlim _gate = new(1, 1);
    private readonly object _stateGate = new();
    private bool _draining;

    public async Task RunAsync(Func<Task> operation)
    {
        ArgumentNullException.ThrowIfNull(operation);
        lock (_stateGate)
        {
            if (_draining)
            {
                throw new InvalidOperationException("Socket is closing.");
            }
        }

        await _gate.WaitAsync();
        try
        {
            lock (_stateGate)
            {
                if (_draining)
                {
                    throw new InvalidOperationException("Socket is closing.");
                }
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
        lock (_stateGate)
        {
            _draining = true;
        }

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
