using System.Text.Json;
using Microsoft.Web.WebView2.Core;
using System.Windows.Threading;

namespace NetSnipe.UI;

public sealed class UiCommandBridge
{
    private static readonly HashSet<string> AllowedActions = new(StringComparer.OrdinalIgnoreCase)
    {
        "Status", "Diagnostics", "PingTest", "DnsTest", "Bufferbloat", "BandwidthRecommendation", "GamingPreview",
        "ProfilePreview", "ApplyProfile", "OptimizeProfile", "RestoreLatest", "StartMonitor", "StopMonitor",
        "MonitorStatus", "MonitorLatest", "ListTargets", "AddTarget", "RemoveTarget", "RestoreWifiScanning",
    };

    private readonly CoreWebView2 _webView;
    private readonly Dispatcher _dispatcher;
    private readonly PowerShellRunner _runner;
    private CancellationTokenSource? _activeCancellation;

    public UiCommandBridge(CoreWebView2 webView, Dispatcher dispatcher, PowerShellRunner runner)
    {
        _webView = webView;
        _dispatcher = dispatcher;
        _runner = runner;
    }

    public void Attach() => _webView.WebMessageReceived += WebMessageReceived;

    private async void WebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs eventArgs)
    {
        using var document = JsonDocument.Parse(eventArgs.WebMessageAsJson);
        var message = document.RootElement;
        var type = message.TryGetProperty("type", out var typeValue) ? typeValue.GetString() : null;
        if (type == "window")
        {
            var windowActionName = message.TryGetProperty("action", out var windowAction) ? windowAction.GetString() : null;
            _ = _dispatcher.BeginInvoke(() => HandleWindowAction(windowActionName));
            return;
        }
        if (type == "cancel")
        {
            _activeCancellation?.Cancel();
            _runner.Cancel();
            return;
        }
        if (type != "run" || !message.TryGetProperty("id", out var idValue) || !message.TryGetProperty("action", out var actionValue)) return;

        var id = idValue.GetString() ?? Guid.NewGuid().ToString("N");
        var action = actionValue.GetString() ?? string.Empty;
        var args = message.TryGetProperty("args", out var argsValue) ? argsValue : default;
        if (!AllowedActions.Contains(action))
        {
            PostResult(id, JsonSerializer.Serialize(new { success = false, action, error = $"Action '{action}' is not allowed." }));
            return;
        }

        using var cancellation = new CancellationTokenSource();
        _activeCancellation = cancellation;
        try
        {
            var output = await _runner.RunAsync(action, args, progress => PostProgress(progress), cancellation.Token);
            PostResult(id, output);
        }
        catch (OperationCanceledException)
        {
            PostResult(id, JsonSerializer.Serialize(new { success = false, action, error = "The operation was cancelled before completion." }));
        }
        catch (Exception ex)
        {
            PostResult(id, JsonSerializer.Serialize(new { success = false, action, error = ex.Message }));
        }
        finally
        {
            if (ReferenceEquals(_activeCancellation, cancellation)) _activeCancellation = null;
        }
    }

    private void PostProgress(JsonElement payload) => PostWebMessage(JsonSerializer.Serialize(new { type = "progress", payload }));

    private void PostResult(string id, string payloadJson)
    {
        try
        {
            using var payload = JsonDocument.Parse(payloadJson);
            PostWebMessage(JsonSerializer.Serialize(new { type = "result", id, payload = payload.RootElement }));
        }
        catch (JsonException)
        {
            PostWebMessage(JsonSerializer.Serialize(new { type = "result", id, payload = new { success = false, error = "The backend returned invalid JSON." } }));
        }
    }

    private void PostWebMessage(string message)
    {
        if (_dispatcher.CheckAccess())
        {
            _webView.PostWebMessageAsJson(message);
            return;
        }

        _ = _dispatcher.BeginInvoke(() => _webView.PostWebMessageAsJson(message));
    }

    private void HandleWindowAction(string? action)
    {
        var window = System.Windows.Application.Current.MainWindow;
        if (window is null) return;
        switch (action)
        {
            case "minimize":
                window.WindowState = System.Windows.WindowState.Minimized;
                break;
            case "maximize":
                window.WindowState = window.WindowState == System.Windows.WindowState.Maximized ? System.Windows.WindowState.Normal : System.Windows.WindowState.Maximized;
                break;
            case "close":
                window.Close();
                break;
            case "drag":
                if (window.WindowState == System.Windows.WindowState.Maximized) window.WindowState = System.Windows.WindowState.Normal;
                try { window.DragMove(); } catch (InvalidOperationException) { }
                break;
        }
    }

    public static string ErrorPage(string message) => $"<!doctype html><html><body style='background:#0a1016;color:#e9f2f8;font-family:Segoe UI;padding:40px'><h1>NetSnipe could not start</h1><p>{System.Net.WebUtility.HtmlEncode(message)}</p><p>Use run.bat dev after installing the developer dependencies.</p></body></html>";
}
