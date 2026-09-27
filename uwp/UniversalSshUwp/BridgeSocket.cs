using System.Threading.Tasks;

namespace UniversalSshUwp;

public interface BridgeSocket
{
    Task ConnectAsync(string host, int port);
    Task WriteAsync(byte[] bytes);
    Task CloseAsync();
}
