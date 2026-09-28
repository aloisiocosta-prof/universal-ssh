using System;
using System.Threading;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketReadLoop
{
    private readonly Func<CancellationToken, Task<byte[]?>> _readChunk;
    private readonly BridgeSocketDataForwarder _forwarder;

    public BridgeSocketReadLoop(
        Func<CancellationToken, Task<byte[]?>> readChunk,
        Func<BridgeEvent, Task> eventSink)
    {
        _readChunk = readChunk ?? throw new ArgumentNullException(nameof(readChunk));
        _forwarder = new BridgeSocketDataForwarder(eventSink);
    }

    public async Task RunAsync(CancellationToken cancellationToken)
    {
        while (true)
        {
            var bytes = await _readChunk(cancellationToken);
            if (bytes is null)
            {
                return;
            }

            await _forwarder.ForwardAsync(bytes);
        }
    }
}
