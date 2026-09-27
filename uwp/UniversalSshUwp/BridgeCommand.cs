using System;
using System.Collections.Generic;
using System.Text.Json;

namespace UniversalSshUwp;

public abstract record BridgeCommand
{
    public static BridgeCommand Parse(string value)
    {
        try
        {
            using var document = JsonDocument.Parse(value);
            var root = document.RootElement;
            var type = root.GetProperty("type").GetString();

            return type switch
            {
                "connect" => ParseConnect(root),
                "data" => ParseData(root),
                "close" => new CloseBridgeCommand(),
                _ => throw new FormatException($"Unknown UWP bridge command: {type}"),
            };
        }
        catch (FormatException)
        {
            throw;
        }
        catch (Exception exception) when (
            exception is JsonException ||
            exception is InvalidOperationException ||
            exception is KeyNotFoundException)
        {
            throw new FormatException("Invalid UWP bridge command.", exception);
        }
    }

    private static ConnectBridgeCommand ParseConnect(JsonElement root)
    {
        var host = root.GetProperty("host").GetString();
        var port = root.GetProperty("port").GetInt32();

        if (string.IsNullOrWhiteSpace(host) || port is < 1 or > 65535)
        {
            throw new FormatException("Invalid UWP bridge connect command.");
        }

        return new ConnectBridgeCommand(host, port);
    }

    private static DataBridgeCommand ParseData(JsonElement root)
    {
        var payload = root.GetProperty("payload").GetString();

        if (payload is null)
        {
            throw new FormatException("Invalid UWP bridge data command.");
        }

        try
        {
            return new DataBridgeCommand(Convert.FromBase64String(payload));
        }
        catch (System.FormatException exception)
        {
            throw new FormatException("Invalid UWP bridge data payload.", exception);
        }
    }
}

public sealed record ConnectBridgeCommand(string Host, int Port) : BridgeCommand;

public sealed record DataBridgeCommand(byte[] Bytes) : BridgeCommand;

public sealed record CloseBridgeCommand : BridgeCommand;
