using System;

namespace UniversalSshUwp;

public sealed class BridgeCommandDispatcher
{
    private readonly Action<BridgeCommand> _consumer;

    public BridgeCommandDispatcher(Action<BridgeCommand> consumer)
    {
        _consumer = consumer ?? throw new ArgumentNullException(nameof(consumer));
    }

    public void Dispatch(string value)
    {
        _consumer(BridgeCommand.Parse(value));
    }
}
