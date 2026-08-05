<div align="center">

# NetSnipe

### A simple, local-first network diagnostics tool for Windows

Check your connection, understand the results and keep your data on your own
computer.

[Download the latest release](https://github.com/Shurielx/NetSnipe/releases/latest)

</div>

---

## Development Status

NetSnipe is currently **not under active development**. I am focusing on other,
more ambitious projects that are currently a higher priority for me.

The project is not abandoned. Once the project I am currently working on is
finished to a level I am satisfied with, I plan to return to NetSnipe and
continue improving it.

This repository currently contains a heavily developer-oriented, unfinished
version. The core assumptions are in place and the basic functionality works,
including settings, adapter information, profile previews and basic ping
tests. However, advanced features are not guaranteed to work correctly, the UI
still needs substantial polishing, and the project should not be treated as a
reliable production or diagnostic tool yet.

The current state has been checked with the backend smoke test and the
frontend production build. That does not mean that every network operation or
advanced feature has been fully tested.

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

## Privacy

NetSnipe is designed to work locally. It does not intentionally include
telemetry or send reports to the author. Runtime data, including targets,
measurements, reports, logs and configuration backups, is stored locally in
`%LOCALAPPDATA%\NetSnipe\`.

Network tests still communicate with the systems required by the test. For
example, ping and DNS tests contact the selected hosts or configured DNS
servers, and the bufferbloat test downloads a temporary test file from a
Cloudflare endpoint. Review the source and the test settings if this matters
for your network or privacy requirements.

## Disclaimer

NetSnipe is provided **as is, without warranty**. It is an unfinished,
developer-oriented project and its results, backups and safeguards are not
guaranteed to be complete or correct.

Some features require Administrator privileges and can modify Windows network
profiles, adapter settings, registry values or other system configuration.
Although NetSnipe attempts to create backups before changes, a backup may be
incomplete, unavailable or impossible to restore. Do not use the profile or
optimization features on a system where you cannot tolerate configuration
changes or possible service interruption. Create your own verified backups
before making changes.

By downloading, installing, launching or using NetSnipe, you acknowledge these
risks and accept responsibility for choosing appropriate targets, settings and
actions, for reviewing the results, and for maintaining your own system
backups. To the maximum extent permitted by applicable law, the author and
contributors are not responsible for data loss, configuration changes, service
interruptions, hardware or software damage, security issues, or any other
losses resulting from the use or inability to use this software.

This notice does not replace the full warranty and liability terms in the
[`GNU GPL v3 license`](LICENSE).

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

The easiest option is to open `devbuild` and double-click:

```text
BUILD-ALL.bat
```

This creates both distributable files:

```text
main: artifacts\installer\NetSnipe-V1.1-Setup-win-x64.exe
      artifacts\NetSnipe-V1.1-Portable-win-x64.zip
beta: artifacts\installer\NetSnipe-B1.1-Setup-win-x64.exe
      artifacts\NetSnipe-B1.1-Portable-win-x64.zip
dev:  artifacts\installer\NetSnipe-D1.1-Setup-win-x64.exe
      artifacts\NetSnipe-D1.1-Portable-win-x64.zip
```

The build reads the current Git branch automatically. `main` creates the
stable `V` build, `beta` creates the test `B` build, and `dev` creates the
developer `D` build. You can override it explicitly with
`-Channel Main`, `-Channel Beta`, or `-Channel Dev`.

For one output only:

```text
BUILD-PORTABLE.bat    Build the portable ZIP
BUILD-INSTALLER.bat   Build the installer EXE
```

The public `devbuild` directory intentionally contains only minimal helper
scripts. Private build archiving and GitHub publishing are kept outside the
public repository.

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
