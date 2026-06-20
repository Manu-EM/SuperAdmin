; SuperAdmin - Inno Setup Installer Script
; Open this file in Inno Setup and press F9 (or Ctrl+F9) to compile

[Setup]
AppName=SuperAdmin
AppVersion=2.0.0
AppPublisher=Tally Super Admin
DefaultDirName={autopf}\SuperAdmin
DefaultGroupName=SuperAdmin
UninstallDisplayIcon={app}\superadmin_app.exe
OutputDir=installer_output
OutputBaseFilename=SuperAdmin_Setup_v2.0
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Tasks]
Name: "desktopicon"; Description: "Create a Desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "build\windows\x64\runner\Release\superadmin_app.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SuperAdmin"; Filename: "{app}\superadmin_app.exe"; IconFilename: "{app}\superadmin_app.exe"
Name: "{group}\Uninstall SuperAdmin"; Filename: "{uninstallexe}"
Name: "{autodesktop}\SuperAdmin"; Filename: "{app}\superadmin_app.exe"; IconFilename: "{app}\superadmin_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\superadmin_app.exe"; Description: "Launch SuperAdmin"; Flags: nowait postinstall skipifsilent
