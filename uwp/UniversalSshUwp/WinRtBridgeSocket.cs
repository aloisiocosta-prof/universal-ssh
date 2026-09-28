using System;
using System.Threading.Tasks;
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

    public Func<BridgeEvent, Task>? EventSink { get; set; }

    public async Task ConnectAsync(string host, int port)
    {
        if (_socket is not null)
        {
            throw new InvalidOperationException("Socket is already connected.");
        }

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
            if (EventSink is not null)
            {
                await EventSink(BridgeEvent.Connected());
                var readLoop = new BridgeSocketReadLoop(ReadChunkAsync, EventSink);
                var supervisor = new BridgeSocketTaskSupervisor(EventSink);
                _readTask = supervisor.RunAsync(readLoop.RunAsync);
            }
        }
        catch
        {
            socket.Dispose();
            throw;
        }
    }

    public async Task WriteAsync(byte[] bytes)
    {
        var writer = _writer ?? throw new InvalidOperationException("Socket is not connected.");
        writer.WriteBytes(bytes);
        await writer.StoreAsync();
    }

    private async Task<byte[]?> ReadChunkAsync()
    {
        var reader = _reader ?? throw new InvalidOperationException("Socket is not connected.");
        var loaded = await reader.LoadAsync(4096);
        if (loaded == 0)
        {
            return null;
        }

        var bytes = new byte[loaded];
        reader.ReadBytes(bytes);
        return bytes;
    }

    public async Task CloseAsync()
    {
        _reader?.Dispose();
        _reader = null;
        _readTask = null;
        _writer?.Dispose();
        _writer = null;
        _socket?.Dispose();
        _socket = null;
        if (EventSink is not null)
        {
            await EventSink(BridgeEvent.Closed());
        }
    }
}
