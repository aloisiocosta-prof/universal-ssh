namespace UniversalSshUwp;

public interface BridgeSocket
{
    void Connect(string host, int port);
    void Write(byte[] bytes);
    void Close();
}
