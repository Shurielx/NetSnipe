#ifndef MyAppName
  #define MyAppName "NetSnipe V1.1 - Main"
#endif
#ifndef MyAppVersion
  #define MyAppVersion "1.1"
#endif
#ifndef MyAppChannel
  #define MyAppChannel "Main"
#endif
#ifndef MyAppId
  #define MyAppId "{{B8B1A8B2-4D9F-4B91-8F39-2A4D6E3C1D72}}"
#endif
#ifndef MyOutputBaseFilename
  #define MyOutputBaseFilename "NetSnipe-V1.1-Setup-win-x64"
#endif
#define MyAppPublisher "NetSnipe"
#define MyAppExeName "NetSnipe.exe"

[Setup]
AppId={#MyAppId}
AppName=NetSnipe {#MyAppChannel}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\NetSnipe\{#MyAppChannel}
DefaultGroupName=NetSnipe {#MyAppChannel}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir=..\artifacts\installer
OutputBaseFilename={#MyOutputBaseFilename}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\artifacts\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\artifacts\prerequisites\MicrosoftEdgeWebView2RuntimeInstallerX64.exe"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall; Check: not IsWebView2Installed

[InstallDelete]
; Application state is stored under LocalAppData, so the install directory can
; be cleared safely before an in-place upgrade. This removes obsolete files.
Type: filesandordirs; Name: "{app}\*"

[Icons]
Name: "{autoprograms}\NetSnipe {#MyAppChannel}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\NetSnipe {#MyAppChannel}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{tmp}\MicrosoftEdgeWebView2RuntimeInstallerX64.exe"; Parameters: "/silent /install"; StatusMsg: "Installing Microsoft Edge WebView2 Runtime..."; Flags: waituntilterminated; Check: not IsWebView2Installed
Filename: "{app}\{#MyAppExeName}"; Description: "Launch NetSnipe"; Flags: shellexec nowait postinstall skipifsilent runasoriginaluser

[UninstallDelete]
Type: dirifempty; Name: "{app}"

[Code]
function IsWebView2Installed: Boolean;
var
  Version: String;
begin
  Result := RegQueryStringValue(HKLM32, 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}', 'pv', Version);
  if not Result then
    Result := RegQueryStringValue(HKLM64, 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}', 'pv', Version);
end;
