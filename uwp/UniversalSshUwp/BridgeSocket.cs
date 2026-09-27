using System;
using System.Threading.Tasks;

namespace UniversalSshUwp;

public interface BridgeSocket
{
    Func<BridgeEvent, Task>? EventSink { get; set; }
    Task ConnectAsync(string host, int port);
    Task WriteAsync(byte[] bytes);
    Task CloseAsync();
}
