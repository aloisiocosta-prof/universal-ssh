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

    public Task CloseAsync()
    {
        _writer?.Dispose();
        _writer = null;
        _socket?.Dispose();
        _socket = null;
        return Task.CompletedTask;
    }
}
