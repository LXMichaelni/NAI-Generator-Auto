@echo off
setlocal

set "FLUTTER_ROOT=D:\Software\flutter"
set "PROJECT_DIR=D:\__easyHelper__\NAI\NAI-Generator-Flutter"

if not exist "%FLUTTER_ROOT%\bin\flutter.bat" (
  echo Flutter not found at: %FLUTTER_ROOT%
  echo Please update FLUTTER_ROOT in build_windows.bat
  pause
  exit /b 1
)

cd /d "%PROJECT_DIR%" || (
  echo Failed to change directory to: %PROJECT_DIR%
  pause
  exit /b 1
)

call "%FLUTTER_ROOT%\bin\flutter.bat" build windows

if not "%~1"=="" (
  set "OUT_DIR=%~1"
  set "SRC_DIR=%PROJECT_DIR%\build\windows\runner\Release"

  if not exist "%SRC_DIR%" (
    echo Build output not found: %SRC_DIR%
    exit /b 2
  )

  if not exist "%OUT_DIR%" (
    mkdir "%OUT_DIR%" || (
      echo Failed to create output directory: %OUT_DIR%
      exit /b 3
    )
  )

  echo Copying build output to: %OUT_DIR%
  robocopy "%SRC_DIR%" "%OUT_DIR%" /E /NFL /NDL /NJH /NJS /NP >nul
  if %ERRORLEVEL% GEQ 8 (
    echo Copy failed with error level %ERRORLEVEL%.
    exit /b 4
  )
)

endlocal
