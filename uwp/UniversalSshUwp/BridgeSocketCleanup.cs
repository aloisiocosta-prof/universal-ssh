using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketCleanup
{
    private readonly Action _cancelRead;
    private readonly Func<Task> _awaitRead;
    private readonly Action _disposeReader;
    private readonly Action _disposeWriter;
    private readonly Action _disposeSocket;

    public BridgeSocketCleanup(
        Action cancelRead,
        Func<Task> awaitRead,
        Action disposeReader,
        Action disposeWriter,
        Action disposeSocket)
    {
        _cancelRead = cancelRead ?? throw new ArgumentNullException(nameof(cancelRead));
        _awaitRead = awaitRead ?? throw new ArgumentNullException(nameof(awaitRead));
        _disposeReader = disposeReader ?? throw new ArgumentNullException(nameof(disposeReader));
        _disposeWriter = disposeWriter ?? throw new ArgumentNullException(nameof(disposeWriter));
        _disposeSocket = disposeSocket ?? throw new ArgumentNullException(nameof(disposeSocket));
    }

    public async Task RunAsync()
    {
        _cancelRead();
        await _awaitRead();
        _disposeReader();
        _disposeWriter();
        _disposeSocket();
    }
}
