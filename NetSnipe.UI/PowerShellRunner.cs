using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.Json;

namespace NetSnipe.UI;

public sealed class PowerShellRunner : IDisposable
{
    private readonly string _root;
    private readonly string _scriptPath;
    private readonly string _dataRoot;
    private Process? _activeProcess;

    public PowerShellRunner(string root)
    {
        _root = root;
        _scriptPath = Path.Combine(root, "NetSnipe.ps1");
        _dataRoot = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "NetSnipe");
    }

    public async Task<string> RunAsync(string action, JsonElement args, Action<JsonElement> onProgress, CancellationToken cancellationToken)
    {
        if (!File.Exists(_scriptPath))
        {
            return JsonSerializer.Serialize(new { success = false, action, error = "NetSnipe.ps1 was not found next to the GUI." });
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            WorkingDirectory = _root,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8,
        };
        startInfo.ArgumentList.Add("-NoProfile");
        startInfo.ArgumentList.Add("-ExecutionPolicy");
        startInfo.ArgumentList.Add("Bypass");
        startInfo.ArgumentList.Add("-File");
        startInfo.ArgumentList.Add(_scriptPath);
        startInfo.ArgumentList.Add("-Action");
        startInfo.ArgumentList.Add(action);
        startInfo.ArgumentList.Add("-JsonOutput");
        startInfo.ArgumentList.Add("-DataRoot");
        startInfo.ArgumentList.Add(_dataRoot);
        AddActionArguments(startInfo, action, args);

        using var process = new Process { StartInfo = startInfo, EnableRaisingEvents = true };
        if (!process.Start())
        {
            return JsonSerializer.Serialize(new { success = false, action, error = "Could not launch PowerShell." });
        }

        _activeProcess = process;
        var output = new StringBuilder();
        var stdoutTask = ReadOutputAsync(process.StandardOutput, output, onProgress);
        var stderrTask = process.StandardError.ReadToEndAsync();
        try
        {
            await process.WaitForExitAsync(cancellationToken);
            await Task.WhenAll(stdoutTask, stderrTask);
        }
        catch (OperationCanceledException)
        {
            TryKill(process);
            await Task.WhenAll(stdoutTask, stderrTask);
            throw;
        }
        finally
        {
            _activeProcess = null;
        }

        var error = await stderrTask;
        if (!string.IsNullOrWhiteSpace(error))
        {
            output.AppendLine();
            output.AppendLine("[PowerShell error]");
            output.AppendLine(error.Trim());
        }

        var finalJson = FindJsonResult(output.ToString());
        return finalJson ?? JsonSerializer.Serialize(new { success = false, action, error = error.Trim().Length > 0 ? error.Trim() : "The backend did not return structured JSON output." });
    }

    public void Cancel()
    {
        if (_activeProcess is { HasExited: false } process) TryKill(process);
    }

    public void Dispose() => Cancel();

    private static async Task ReadOutputAsync(StreamReader reader, StringBuilder output, Action<JsonElement> onProgress)
    {
        while (await reader.ReadLineAsync().ConfigureAwait(false) is { } line)
        {
            output.AppendLine(line);
            const string prefix = "NETSNIPE_PROGRESS ";
            if (!line.StartsWith(prefix, StringComparison.Ordinal)) continue;
            try
            {
                using var document = JsonDocument.Parse(line[prefix.Length..]);
                onProgress(document.RootElement.Clone());
            }
            catch (JsonException)
            {
                // Ignore malformed progress and wait for the final result.
            }
        }
    }

    private static string? FindJsonResult(string output)
    {
        var lines = output.Split(new[] { "\r\n", "\n" }, StringSplitOptions.RemoveEmptyEntries);
        for (var index = lines.Length - 1; index >= 0; index--)
        {
            var candidate = lines[index].Trim();
            if (!candidate.StartsWith("{")) continue;
            try
            {
                using var document = JsonDocument.Parse(candidate);
                return candidate;
            }
            catch (JsonException)
            {
                // PowerShell writes progress and host messages before the final JSON line.
            }
        }

        return null;
    }

    private static void AddActionArguments(ProcessStartInfo startInfo, string action, JsonElement args)
    {
        switch (action)
        {
            case "Diagnostics":
                AddInt(startInfo, args, "DiagnosticSeconds", 60, 15, 900);
                break;
            case "PingTest":
                AddString(startInfo, args, "PingTarget", required: true);
                AddInt(startInfo, args, "PingRate", 2, 1, 10);
                AddInt(startInfo, args, "PingSeconds", 30, 5, 900);
                break;
            case "Bufferbloat":
                AddInt(startInfo, args, "BufferbloatDownloadMb", 10, 5, 50);
                AddInt(startInfo, args, "BufferbloatSeconds", 90, 10, 90);
                break;
            case "ProfilePreview":
            case "ApplyProfile":
            case "OptimizeProfile":
                AddString(startInfo, args, "Profile", required: true);
                if (TryGetString(args, "ChannelWidth", out var width)) AddArgument(startInfo, "-ChannelWidth", width);
                if (action == "OptimizeProfile") AddInt(startInfo, args, "DiagnosticSeconds", 15, 15, 900);
                break;
            case "AddTarget":
                AddString(startInfo, args, "TargetName", required: true);
                AddString(startInfo, args, "TargetAddress", required: true);
                break;
            case "RemoveTarget":
                AddString(startInfo, args, "TargetId", required: true);
                break;
            case "Status":
            case "ListTargets":
            case "DnsTest":
            case "BandwidthRecommendation":
            case "GamingPreview":
            case "RestoreLatest":
            case "StartMonitor":
            case "StopMonitor":
            case "MonitorStatus":
            case "MonitorLatest":
                break;
            default:
                throw new InvalidOperationException($"Action '{action}' is not allowed through the GUI bridge.");
        }
    }

    private static void AddString(ProcessStartInfo info, JsonElement args, string name, bool required)
    {
        if (!TryGetString(args, name, out var value) || (required && string.IsNullOrWhiteSpace(value))) throw new ArgumentException($"Missing argument: {name}");
        AddArgument(info, $"-{name}", value);
    }

    private static void AddInt(ProcessStartInfo info, JsonElement args, string name, int fallback, int min, int max)
    {
        var value = args.TryGetProperty(name, out var element) && element.TryGetInt32(out var parsed) ? parsed : fallback;
        if (value < min || value > max) throw new ArgumentOutOfRangeException(name, $"Value must be between {min} and {max}.");
        AddArgument(info, $"-{name}", value.ToString(System.Globalization.CultureInfo.InvariantCulture));
    }

    private static bool TryGetString(JsonElement args, string property, out string value)
    {
        if (args.TryGetProperty(property, out var element) && element.ValueKind == JsonValueKind.String)
        {
            value = element.GetString() ?? string.Empty;
            return true;
        }
        value = string.Empty;
        return false;
    }

    private static void AddArgument(ProcessStartInfo info, string name, string value)
    {
        info.ArgumentList.Add(name);
        info.ArgumentList.Add(value);
    }

    private static void TryKill(Process process)
    {
        try
        {
            if (!process.HasExited) process.Kill(entireProcessTree: true);
        }
        catch (InvalidOperationException) { }
        catch (System.ComponentModel.Win32Exception) { }
    }
}
