namespace UniversalSshUwp;

public sealed class BridgeSocketLifecycle
{
    private readonly object _gate = new();
    private State _state = State.Disconnected;

    public void MarkConnected()
    {
        lock (_gate)
        {
            _state = State.Connected;
        }
    }

    public bool TryBeginClose()
    {
        lock (_gate)
        {
            if (_state != State.Connected)
            {
                return false;
            }

            _state = State.Closing;
            return true;
        }
    }

    public void MarkClosed()
    {
        lock (_gate)
        {
            _state = State.Closed;
        }
    }

    private enum State
    {
        Disconnected,
        Connected,
        Closing,
        Closed,
    }
}
