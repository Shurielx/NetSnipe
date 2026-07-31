using System.IO;
using System.Windows;
using System.Windows.Input;
using Microsoft.Web.WebView2.Core;

namespace NetSnipe.UI;

public partial class MainWindow : Window
{
    private readonly PowerShellRunner _runner;
    private UiCommandBridge? _bridge;

    public MainWindow()
    {
        InitializeComponent();
        _runner = new PowerShellRunner(FindBackendRoot());
        Loaded += MainWindow_Loaded;
        Closed += (_, _) => _runner.Dispose();
    }

    private async void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        try
        {
            var webViewDataPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "NetSnipe",
                "WebView2");
            Directory.CreateDirectory(webViewDataPath);
            var webViewEnvironment = await CoreWebView2Environment.CreateAsync(
                browserExecutableFolder: null,
                userDataFolder: webViewDataPath);
            await Browser.EnsureCoreWebView2Async(webViewEnvironment);
            Browser.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
            Browser.CoreWebView2.Settings.AreDevToolsEnabled = true;
            Browser.CoreWebView2.Settings.IsZoomControlEnabled = false;

            _bridge = new UiCommandBridge(Browser.CoreWebView2, Dispatcher, _runner);
            _bridge.Attach();

            var frontendPath = ResolveFrontendPath();
            if (!Directory.Exists(frontendPath))
            {
                Browser.NavigateToString(UiCommandBridge.ErrorPage("The local frontend build was not found. Run run.bat dev first."));
                return;
            }

            Browser.CoreWebView2.SetVirtualHostNameToFolderMapping(
                "netsnipe.local",
                frontendPath,
                CoreWebView2HostResourceAccessKind.Allow);
            Browser.CoreWebView2.Navigate("https://netsnipe.local/index.html");
        }
        catch (Exception ex)
        {
            Browser.NavigateToString(UiCommandBridge.ErrorPage($"WebView2 could not be initialized: {ex.Message}"));
        }
    }

    private void TitleBar_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ClickCount == 2)
        {
            ToggleMaximize();
            return;
        }

        try { DragMove(); } catch (InvalidOperationException) { }
    }

    private void MinimizeButton_Click(object sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void MaximizeButton_Click(object sender, RoutedEventArgs e) => ToggleMaximize();

    private void CloseButton_Click(object sender, RoutedEventArgs e) => Close();

    private void ToggleMaximize() => WindowState = WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized;

    private static string FindBackendRoot()
    {
        var candidates = new[]
        {
            Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..")),
            AppContext.BaseDirectory,
        };
        return candidates.FirstOrDefault(path =>
            File.Exists(Path.Combine(path, "NetSnipe.ps1")) && Directory.Exists(Path.Combine(path, "backend")))
            ?? AppContext.BaseDirectory;
    }

    private static string ResolveFrontendPath()
    {
        var outputFrontend = Path.Combine(AppContext.BaseDirectory, "frontend");
        if (Directory.Exists(outputFrontend)) return outputFrontend;
        var projectFrontend = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "NetSnipe.UI", "Frontend", "dist"));
        return projectFrontend;
    }
}
