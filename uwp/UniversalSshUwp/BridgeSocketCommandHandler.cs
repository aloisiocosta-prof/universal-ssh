using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public sealed class BridgeSocketCommandHandler
{
    private readonly BridgeSocket _socket;

    public BridgeSocketCommandHandler(BridgeSocket socket)
    {
        _socket = socket ?? throw new ArgumentNullException(nameof(socket));
    }

    public Task HandleAsync(BridgeCommand command) =>
        command switch
        {
            ConnectBridgeCommand connect => _socket.ConnectAsync(connect.Host, connect.Port),
            DataBridgeCommand data => _socket.WriteAsync(data.Bytes),
            CloseBridgeCommand => _socket.CloseAsync(),
            _ => throw new ArgumentOutOfRangeException(nameof(command)),
        };
}
