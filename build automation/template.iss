; Inno Setup Script Template
[Setup]
AppName={{APP_DISPLAY_NAME}}
AppPublisher={{APP_PUBLISHER}}
AppCopyright=© {{APP_YEAR}} {{APP_PUBLISHER}}
AppVersion={{APP_VERSION}}
DefaultDirName={commonpf}\{{APP_BINARY_NAME}}
DefaultGroupName={{APP_DISPLAY_NAME}}
OutputBaseFilename={{APP_BINARY_NAME}}-Windows64_Installer
Compression=lzma
SolidCompression=yes
DisableDirPage=no
SetupIconFile=resources\icons\favicon.ico

[Files]
Source: "dist\{{APP_BINARY_NAME}}\{{APP_BINARY_NAME}}-win_x64.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\{{APP_BINARY_NAME}}\resources.neu"; DestDir: "{app}"; Flags: ignoreversion
Source: "resources\icons\favicon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{{APP_DISPLAY_NAME}}"; Filename: "{app}\{{APP_BINARY_NAME}}-win_x64.exe"; IconFilename: "{app}\favicon.ico"
Name: "{commondesktop}\{{APP_DISPLAY_NAME}}"; Filename: "{app}\{{APP_BINARY_NAME}}-win_x64.exe"; IconFilename: "{app}\favicon.ico"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:" 
