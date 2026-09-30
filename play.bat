@echo off
rem Launch Frontier Expedition from source with Godot 4.7.2.
rem Double-click this file. Close the game window to quit.
rem
rem Note: %~dp0 ends with a backslash. Passing "%~dp0" as an argument gives Godot
rem "C:\...\frontier-expedition\" and that final \" escapes the closing quote, so the
rem path arrives malformed. The trailing backslash is stripped below.
cd /d "%~dp0"

rem Pull the latest version from GitHub first, so the game is always current.
rem Skipped quietly when Git isn't installed or this folder isn't a Git clone; if the pull
rem fails (offline, or local edits in the way) the game still starts with what's here.
if exist ".git" (
  where git >nul 2>nul
  if not errorlevel 1 (
    echo Checking GitHub for updates...
    git pull --ff-only origin main
    if errorlevel 1 (
      echo.
      echo Could not update ^(offline, or local changes in the way^). Starting the current version.
      echo.
    )
  )
)

set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"

rem Console build, so script errors are visible while playtesting.
set "GODOT=C:\Users\btd08\tools\godot\Godot_v4.7.2-stable_win64_console.exe"

if not exist "%GODOT%" (
  echo.
  echo Godot was not found at:
  echo   %GODOT%
  echo.
  echo Install Godot 4.7.2 there, or edit this file to point at yours.
  echo Download: https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip
  echo.
  pause
  exit /b 1
)

if not exist "%REPO%\project.godot" (
  echo.
  echo No project.godot in:
  echo   %REPO%
  echo.
  pause
  exit /b 1
)

echo Launching Frontier Expedition from:
echo   %REPO%
echo.
"%GODOT%" --path "%REPO%"

rem Only pause when something went wrong, so a normal close does not hold the window.
if errorlevel 1 (
  echo.
  echo The game exited with code %errorlevel%.
  pause
)
