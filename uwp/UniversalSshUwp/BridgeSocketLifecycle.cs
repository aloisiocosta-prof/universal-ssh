namespace UniversalSshUwp;

public sealed class BridgeSocketLifecycle
{
    private readonly object _gate = new();
    private State _state = State.Disconnected;

    public bool TryBeginConnect()
    {
        lock (_gate)
        {
            if (_state is not (State.Disconnected or State.Closed))
            {
                return false;
            }

            _state = State.Connecting;
            return true;
        }
    }

    public void MarkConnectFailed()
    {
        lock (_gate)
        {
            if (_state is State.Connecting or State.Connected)
            {
                _state = State.Disconnected;
            }
        }
    }

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
        Connecting,
        Connected,
        Closing,
        Closed,
    }
}
