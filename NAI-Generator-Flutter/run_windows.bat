@echo off
setlocal

set "FLUTTER_ROOT=D:\Software\flutter"
set "PROJECT_DIR=%~dp0"

if not exist "%FLUTTER_ROOT%\bin\flutter.bat" (
  echo Flutter not found at: %FLUTTER_ROOT%
  echo Please update FLUTTER_ROOT in run_windows.bat
  pause
  exit /b 1
)

cd /d "%PROJECT_DIR%" || (
  echo Failed to change directory to: %PROJECT_DIR%
  pause
  exit /b 1
)

if /i "%~1"=="clean" (
  echo Running flutter clean...
  call "%FLUTTER_ROOT%\bin\flutter.bat" clean

  if exist "windows\flutter\ephemeral" (
    echo Removing windows\flutter\ephemeral...
    rmdir /s /q "windows\flutter\ephemeral"
  )
  if exist "linux\flutter\ephemeral" (
    echo Removing linux\flutter\ephemeral...
    rmdir /s /q "linux\flutter\ephemeral"
  )

  if exist "windows\flutter\ephemeral" (
    echo Failed to remove windows\flutter\ephemeral. Close Flutter/Dart/IDE processes and try again.
    exit /b 2
  )
)

call "%FLUTTER_ROOT%\bin\flutter.bat" run -d windows

endlocal
