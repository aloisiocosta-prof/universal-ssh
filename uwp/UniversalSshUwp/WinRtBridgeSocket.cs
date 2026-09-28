using System;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.Networking;
using Windows.Networking.Sockets;
using Windows.Storage.Streams;

namespace UniversalSshUwp;

public sealed class WinRtBridgeSocket : BridgeSocket
{
    private StreamSocket? _socket;
    private DataWriter? _writer;
    private DataReader? _reader;
    private Task? _readTask;
    private CancellationTokenSource? _readCancellation;
    private readonly BridgeSocketLifecycle _lifecycle = new();
    private readonly BridgeSocketWriteGate _writeGate = new();

    public Func<BridgeEvent, Task>? EventSink { get; set; }

    public async Task ConnectAsync(string host, int port)
    {
        if (_socket is not null)
        {
            throw new InvalidOperationException("Socket is already connected.");
        }

        var eventSink = BridgeSocketEventSink.Require(EventSink);
        var socket = new StreamSocket();
        try
        {
            await socket.ConnectAsync(new HostName(host), port.ToString());
            _socket = socket;
            _writer = new DataWriter(socket.OutputStream);
            _reader = new DataReader(socket.InputStream)
            {
                InputStreamOptions = InputStreamOptions.Partial,
            };
            await eventSink(BridgeEvent.Connected());
            _writeGate.Reset();
            _lifecycle.MarkConnected();
            _readCancellation = new CancellationTokenSource();
            var readLoop = new BridgeSocketReadLoop(ReadChunkAsync, eventSink);
            var supervisor = new BridgeSocketTaskSupervisor(eventSink);
            _readTask = supervisor.RunAsync(() => readLoop.RunAsync(_readCancellation.Token));
        }
        catch
        {
            if (_socket is null)
            {
                socket.Dispose();
            }
            else
            {
                await CreateCleanup().RunAsync();
            }
            throw;
        }
    }

    public Task WriteAsync(byte[] bytes) =>
        _writeGate.RunAsync(async () =>
        {
            var writer = _writer ?? throw new InvalidOperationException("Socket is not connected.");
            writer.WriteBytes(bytes);
            await writer.StoreAsync();
        });

    private async Task<byte[]?> ReadChunkAsync(CancellationToken cancellationToken)
    {
        var reader = _reader ?? throw new InvalidOperationException("Socket is not connected.");
        var loaded = await reader.LoadAsync(4096).AsTask(cancellationToken);
        if (loaded == 0)
        {
            return null;
        }

        var bytes = new byte[loaded];
        reader.ReadBytes(bytes);
        return bytes;
    }

    private BridgeSocketCleanup CreateCleanup() =>
        new(
            cancelRead: () => _readCancellation?.Cancel(),
            awaitRead: async () =>
            {
                if (_readTask is not null)
                {
                    await _readTask;
                }
            },
            disposeReader: () =>
            {
                _readCancellation?.Dispose();
                _readCancellation = null;
                _readTask = null;
                _reader?.Dispose();
                _reader = null;
            },
            disposeWriter: () =>
            {
                _writer?.Dispose();
                _writer = null;
            },
            disposeSocket: () =>
            {
                _socket?.Dispose();
                _socket = null;
            });

    public async Task CloseAsync()
    {
        if (!_lifecycle.TryBeginClose())
        {
            return;
        }

        try
        {
            await _writeGate.DrainAsync(() => CreateCleanup().RunAsync());
        }
        finally
        {
            _lifecycle.MarkClosed();
        }

        if (EventSink is not null)
        {
            await EventSink(BridgeEvent.Closed());
        }
    }
}
