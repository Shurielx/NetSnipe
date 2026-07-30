#define MyAppName "NetSnipe"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "NetSnipe"
#define MyAppExeName "NetSnipe.exe"

[Setup]
AppId={{B8B1A8B2-4D9F-4B91-8F39-2A4D6E3C1D72}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\NetSnipe
DefaultGroupName=NetSnipe
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir=..\artifacts\installer
OutputBaseFilename=NetSnipe-Setup-win-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\artifacts\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\artifacts\prerequisites\MicrosoftEdgeWebView2RuntimeInstallerX64.exe"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall; Check: not IsWebView2Installed

[Dirs]
Name: "{localappdata}\NetSnipe"

[Icons]
Name: "{autoprograms}\NetSnipe"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\NetSnipe"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{tmp}\MicrosoftEdgeWebView2RuntimeInstallerX64.exe"; Parameters: "/silent /install"; StatusMsg: "Installing Microsoft Edge WebView2 Runtime..."; Flags: waituntilterminated; Check: not IsWebView2Installed
Filename: "{app}\{#MyAppExeName}"; Description: "Launch NetSnipe"; Flags: nowait postinstall skipifsilent

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
