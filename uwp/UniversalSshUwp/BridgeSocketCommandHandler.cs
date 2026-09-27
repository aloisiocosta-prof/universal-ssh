using System;

namespace UniversalSshUwp;

public sealed class BridgeSocketCommandHandler
{
    private readonly BridgeSocket _socket;

    public BridgeSocketCommandHandler(BridgeSocket socket)
    {
        _socket = socket ?? throw new ArgumentNullException(nameof(socket));
    }

    public void Handle(BridgeCommand command)
    {
        switch (command)
        {
            case ConnectBridgeCommand connect:
                _socket.Connect(connect.Host, connect.Port);
                break;
            case DataBridgeCommand data:
                _socket.Write(data.Bytes);
                break;
            case CloseBridgeCommand:
                _socket.Close();
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(command));
        }
    }
}
