; Ka7 installer for Windows (Inno Setup 6).
; Built by .github/workflows/windows.yml:
;   iscc /DVersion=0.3.3 /DSource=<Release folder> /DOutput=<dist> ka7.iss
; Per-user install (no admin rights): %LOCALAPPDATA%\Programs\Ka7.

#ifndef Version
  #define Version "0.0.0"
#endif
#ifndef Source
  #define Source "..\..\app\build\windows\x64\runner\Release"
#endif
#ifndef Output
  #define Output "..\..\dist"
#endif

[Setup]
; Never change: Windows knows Ka7 by it, for updates and uninstall.
AppId={{F6F317E2-6BC8-40C9-857C-9C847A5C4AF5}
AppName=Ka7
AppVersion={#Version}
AppVerName=Ka7 {#Version}
AppPublisher=Rakoto Ketrika
AppCopyright=Copyright 2026 Rakoto Ketrika
DefaultDirName={autopf}\Ka7
DefaultGroupName=Ka7
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#Output}
OutputBaseFilename=Ka7-{#Version}-windows-setup
SetupIconFile=..\..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\ka7.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#Source}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Ka7"; Filename: "{app}\ka7.exe"
Name: "{autodesktop}\Ka7"; Filename: "{app}\ka7.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\ka7.exe"; Description: "{cm:LaunchProgram,Ka7}"; Flags: nowait postinstall skipifsilent
