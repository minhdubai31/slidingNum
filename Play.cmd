@echo off
set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot was not found. Import project.godot in your installed Godot editor.
  pause
  exit /b 1
)
start "Slide" "%GODOT_EXE%" --path "%~dp0"
