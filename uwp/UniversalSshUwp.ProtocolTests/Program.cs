using System;
using UniversalSshUwp;

static class BridgeProtocolTests
{
    static int Main()
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

        return 0;
    }
}
