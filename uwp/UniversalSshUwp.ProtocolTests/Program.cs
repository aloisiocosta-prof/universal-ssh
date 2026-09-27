using System;
using UniversalSshUwp;

static class BridgeProtocolTests
{
    static async Task<int> Main()
    {
        var connect = BridgeCommand.Parse("""{"type":"connect","host":"ssh.example.test","port":22}""");
        if (connect is not ConnectBridgeCommand c || c.Host != "ssh.example.test" || c.Port != 22) return 1;

        var data = BridgeCommand.Parse("""{"type":"data","payload":"U1NI"}""");
        if (data is not DataBridgeCommand d || Convert.ToBase64String(d.Bytes) != "U1NI") return 2;

        if (BridgeCommand.Parse("""{"type":"close"}""") is not CloseBridgeCommand) return 3;

        try
        {
            BridgeCommand.Parse("""{"type":"connect","host":"","port":22}""");
            return 4;
        }
        catch (FormatException) { }

        try
        {
            BridgeCommand.Parse("""{"type":"unknown"}""");
            return 5;
        }
        catch (FormatException) { }

        BridgeCommand? dispatched = null;
        var dispatcher = new BridgeCommandDispatcher(command => dispatched = command);
        dispatcher.Dispatch("""{"type":"close"}""");
        if (dispatched is not CloseBridgeCommand) return 6;

        BridgeCommand? hostCommand = null;
        var host = new BridgeHostController(
            new BridgeCommandDispatcher(command => hostCommand = command));
        host.Receive("""{"type":"connect","host":"ssh.example.test","port":22}""");
        if (hostCommand is not ConnectBridgeCommand hc ||
            hc.Host != "ssh.example.test" ||
            hc.Port != 22) return 7;

        var socket = new RecordingBridgeSocket();
        var handler = new BridgeSocketCommandHandler(socket);
        await handler.HandleAsync(new ConnectBridgeCommand("ssh.example.test", 22));
        await handler.HandleAsync(new DataBridgeCommand(new byte[] { 0x53, 0x53, 0x48 }));
        await handler.HandleAsync(new CloseBridgeCommand());
        if (socket.Host != "ssh.example.test" || socket.Port != 22) return 8;
        if (Convert.ToBase64String(socket.Bytes ?? Array.Empty<byte>()) != "U1NI") return 9;
        if (!socket.Closed) return 10;

        var composedSocket = new RecordingBridgeSocket();
        var composedHost = BridgeHostController.ForSocket(composedSocket);
        await composedHost.ReceiveAsync("""{"type":"connect","host":"ssh.example.test","port":22}""");
        await composedHost.ReceiveAsync("""{"type":"data","payload":"U1NI"}""");
        await composedHost.ReceiveAsync("""{"type":"close"}""");
        if (composedSocket.Host != "ssh.example.test" || composedSocket.Port != 22) return 11;
        if (Convert.ToBase64String(composedSocket.Bytes ?? Array.Empty<byte>()) != "U1NI") return 12;
        if (!composedSocket.Closed) return 13;

        var asyncSocket = new AsyncRecordingBridgeSocket();
        var asyncHost = BridgeHostController.ForSocket(asyncSocket);
        await asyncHost.ReceiveAsync("""{"type":"connect","host":"ssh.example.test","port":22}""");
        await asyncHost.ReceiveAsync("""{"type":"data","payload":"U1NI"}""");
        await asyncHost.ReceiveAsync("""{"type":"close"}""");
        if (asyncSocket.Operations != "connect,data,close") return 14;
        return 0;
    }
}


sealed class RecordingBridgeSocket : BridgeSocket
{
    public string? Host { get; private set; }
    public int Port { get; private set; }
    public byte[]? Bytes { get; private set; }
    public bool Closed { get; private set; }

    public Task ConnectAsync(string host, int port)
    {
        Host = host;
        Port = port;
        return Task.CompletedTask;
    }

    public Task WriteAsync(byte[] bytes)
    {
        Bytes = bytes;
        return Task.CompletedTask;
    }

    public Task CloseAsync()
    {
        Closed = true;
        return Task.CompletedTask;
    }
}

sealed class AsyncRecordingBridgeSocket : BridgeSocket
{
    private readonly List<string> _operations = new();
    public string Operations => string.Join(",", _operations);

    public async Task ConnectAsync(string host, int port)
    {
        await Task.Yield();
        _operations.Add("connect");
    }

    public async Task WriteAsync(byte[] bytes)
    {
        await Task.Yield();
        _operations.Add("data");
    }

    public async Task CloseAsync()
    {
        await Task.Yield();
        _operations.Add("close");
    }
}
