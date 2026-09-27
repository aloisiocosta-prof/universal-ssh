using System;

namespace UniversalSshUwp;

public sealed class BridgeHostController
{
    private readonly BridgeCommandDispatcher _dispatcher;

    public BridgeHostController(BridgeCommandDispatcher dispatcher)
    {
        _dispatcher = dispatcher ?? throw new ArgumentNullException(nameof(dispatcher));
    }

    public void Receive(string value)
    {
        _dispatcher.Dispatch(value);
    }
}
