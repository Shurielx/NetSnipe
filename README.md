<div align="center">

# NetSnipe

### A simple, local-first network diagnostics tool for Windows

Check your connection, understand the results and keep your data on your own
computer.

[Download the latest release](https://github.com/Shurielx/NetSnipe/releases/latest)

</div>

---

## Start Here

Most people should download the installer:

| Download | When to use it |
| --- | --- |
| [`NetSnipe-Setup-win-x64.exe`](https://github.com/Shurielx/NetSnipe/releases/latest) | Recommended. Installs NetSnipe and creates shortcuts. |
| `NetSnipe-Portable-win-x64.zip` | No installation. Extract it and run `NetSnipe.exe`. |

NetSnipe may ask for Administrator permission. This is required by Windows for
some adapter and network profile operations.

## What NetSnipe Does

- Shows your adapter, IP address, gateway and DNS details.
- Runs ping tests with latency, jitter and packet loss.
- Tests custom hosts and saves custom targets.
- Checks DNS performance.
- Runs bufferbloat tests.
- Monitors your connection over time.
- Manages network profiles and creates backups before changes.
- Saves reports and logs locally.

## Good To Know

- Designed for Windows 10/11 x64.
- The installer can install Microsoft Edge WebView2 Runtime if it is missing.
- Runtime data is stored locally in:

  ```text
  %LOCALAPPDATA%\NetSnipe\
  ```

- Read-only diagnostics do not change your settings. Profile and adapter
  actions can make changes, with backups created first.

## Beta Version

The `beta` branch contains changes for public testing. It may include bugs or
unfinished behaviour and is not guaranteed to be stable.

For everyday use, download the official version from
[Releases](https://github.com/Shurielx/NetSnipe/releases).

Read the full beta notice in [`BETA.md`](BETA.md).

---

## For Developers

### Requirements

- Windows 10/11 x64
- Windows PowerShell 5.1
- .NET 8 SDK
- Node.js and npm
- Microsoft Edge WebView2 Runtime
- Inno Setup 6 for building the installer

Install frontend dependencies once:

```bat
setup-dev.bat
```

Run the local application:

```bat
run.bat
```

Available modes:

```text
run.bat          Automatically choose GUI or CLI
run.bat auto     Automatically choose GUI or CLI
run.bat dev      Build the frontend and run the GUI
run.bat gui      Run the already-built GUI
run.bat cli      Run the PowerShell CLI
```

### Build A Release

The easiest way is to open `devbuild` and double-click:

```text
BUILD-ALL.bat
```

This creates both distributable files:

```text
artifacts\installer\NetSnipe-Setup-win-x64.exe
artifacts\NetSnipe-Portable-win-x64.zip
```

For one output only:

```text
BUILD-PORTABLE.bat    Build the portable ZIP
BUILD-INSTALLER.bat   Build the installer EXE
```

The click-by-click guide is in [`devbuild/README.txt`](devbuild/README.txt).

The same build can be started from PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build-release.ps1
```

### Verify The Project

```powershell
npm.cmd --prefix NetSnipe.UI\Frontend run build
dotnet build NetSnipe.UI\NetSnipe.UI.csproj --configuration Debug --no-restore
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\BackendSmoke.ps1
```

### Project Layout

```text
backend/                 PowerShell network modules
NetSnipe.UI/             WPF/WebView2 host and React frontend
tests/                   Parser and backend smoke tests
installer/               Inno Setup installer definition
devbuild/                Click-to-build helpers
build-release.ps1        Release build script
```

Generated files in `artifacts` are intentionally ignored by Git. Release
binaries are published through GitHub Releases instead of being committed to
the source tree.

## Contributing

Bug reports, ideas and pull requests are welcome. Please include a short
description of the change and the checks you ran.

## License

NetSnipe is released under the
[GNU General Public License v3.0](LICENSE).
