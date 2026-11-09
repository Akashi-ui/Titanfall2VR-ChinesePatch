@echo off
setlocal
where cl >nul 2>nul
if errorlevel 1 (
  echo Run this script from an x64 Native Tools Command Prompt for Visual Studio.
  exit /b 1
)
set "BUILD_DIR=%~dp0..\dist\plugin"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
lib /nologo /def:"%~dp0caption_kernel32.def" /machine:x64 /out:"%BUILD_DIR%\caption_kernel32.lib"
if errorlevel 1 exit /b 1
cl /nologo /LD /O2 /GS- /GR- /W4 /Fo:"%BUILD_DIR%\caption_layout_plugin.obj" "%~dp0caption_layout_plugin.cpp" /link /NODEFAULTLIB /NOENTRY "%BUILD_DIR%\caption_kernel32.lib" /OUT:"%BUILD_DIR%\Chinese.CaptionLayout.dll"
exit /b %errorlevel%
