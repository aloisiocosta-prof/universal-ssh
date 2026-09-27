using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketReadLoop
{
    private readonly Func<Task<byte[]?>> _readChunk;
    private readonly BridgeSocketDataForwarder _forwarder;

    public BridgeSocketReadLoop(
        Func<Task<byte[]?>> readChunk,
        Func<BridgeEvent, Task> eventSink)
    {
        _readChunk = readChunk ?? throw new ArgumentNullException(nameof(readChunk));
        _forwarder = new BridgeSocketDataForwarder(eventSink);
    }

    public async Task RunAsync()
    {
        while (true)
        {
            var bytes = await _readChunk();
            if (bytes is null)
            {
                return;
            }

            await _forwarder.ForwardAsync(bytes);
        }
    }
}
