using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeHostController
{
    private readonly BridgeCommandDispatcher _dispatcher;
    private readonly Func<BridgeCommand, Task>? _asyncConsumer;

    public BridgeHostController(BridgeCommandDispatcher dispatcher)
    {
        _dispatcher = dispatcher ?? throw new ArgumentNullException(nameof(dispatcher));
    }

    private BridgeHostController(
        BridgeCommandDispatcher dispatcher,
        Func<BridgeCommand, Task> asyncConsumer)
    {
        _dispatcher = dispatcher;
        _asyncConsumer = asyncConsumer;
    }

    public static BridgeHostController ForSocket(BridgeSocket socket)
    {
        var handler = new BridgeSocketCommandHandler(socket);
        return new BridgeHostController(
            new BridgeCommandDispatcher(_ => { }),
            handler.HandleAsync);
    }

    public void Receive(string value)
    {
        _dispatcher.Dispatch(value);
    }

    public Task ReceiveAsync(string value)
    {
        if (_asyncConsumer is null)
        {
            throw new InvalidOperationException("This controller has no asynchronous consumer.");
        }

        return _asyncConsumer(BridgeCommand.Parse(value));
    }
}
