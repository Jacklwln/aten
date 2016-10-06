; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Aten"
#define MyAppVersion "2.1.5"
#define MyAppPublisher "Tristan Youngs"
#define MyAppURL "http://www.projectaten.net/"
#define MyAppExeName "Aten.exe"

; Locations of bin directories of Qt, GnuWin(32), and MinGW(32)
#define QtDir "C:\Qt\5.7.0\5.7"
#define GnuWinDir "C:\GnuWin32"
#define MinGWDir "C:\MinGW32"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{8DF93A4D-C712-41C4-B8EE-75484080B32F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\Aten2
DefaultGroupName={#MyAppName}
LicenseFile=..\..\COPYING
OutputDir=..\..\
OutputBaseFilename=Aten-2.1.5
SetupIconFile=Aten.ico
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\bin\Aten.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\..\data\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\build\data\plugins\*"; DestDir: "{app}\plugins"; Flags: ignoreversion
Source: "..\..\build\lib\libaten.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "Aten.ico"; DestDir: "{app}\bin"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
Source: "{#GnuWinDir}\bin\freetype6.dll"; DestDir: "{app}\bin"
Source: "{#GnuWinDir}\bin\readline5.dll"; DestDir: "{app}\bin"
Source: "{#GnuWinDir}\bin\history5.dll"; DestDir: "{app}\bin"
Source: "{#GnuWinDir}\bin\zlib1.dll"; DestDir: "{app}\bin"
Source: "{#GnuWinDir}\bin\libftgl.dll"; DestDir: "{app}\bin"
Source: "{#MinGWDir}\bin\libgcc_s_dw2-1.dll"; DestDir: "{app}\bin"
Source: "{#MinGWDir}\bin\libstdc++-6.dll"; DestDir: "{app}\bin"
Source: "{#MinGWDir}\bin\libwinpthread-1.dll"; DestDir: "{app}\bin"
Source: "{#QtDir}\bin\Qt5Gui.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#QtDir}\bin\Qt5Core.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#QtDir}\bin\Qt5OpenGL.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#QtDir}\bin\Qt5Svg.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#QtDir}\bin\Qt5Widgets.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#QtDir}\bin\libEGL.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#QtDir}\bin\libGLESv2.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#QtDir}\plugins\iconengines\qsvgicon.dll"; DestDir: "{app}\bin\iconengines"; Flags: ignoreversion
Source: "{#QtDir}\plugins\platforms\qwindows.dll"; DestDir: "{app}\bin\platforms"; Flags: ignoreversion
Source: "{#QtDir}\plugins\imageformats\*.dll"; DestDir: "{app}\bin\imageformats"; Flags: ignoreversion
Source: "C:\Windows\System32\D3DCompiler_43.dll"; DestDir: "{app}\bin"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; IconFilename: "{app}\bin\Aten.ico"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{commondesktop}\{#MyAppName}"; IconFilename: "{app}\bin\Aten.ico"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
