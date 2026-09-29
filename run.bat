@echo off
REM ====================================================================
REM  DengueTriage-ES  --  launcher for Windows
REM  Double-click this file, or run it from a Command Prompt.
REM ====================================================================
setlocal
cd /d "%~dp0"

set "SWIPL="
where swipl >nul 2>nul && set "SWIPL=swipl"
if not defined SWIPL if exist "%ProgramFiles%\swipl\bin\swipl.exe" set "SWIPL=%ProgramFiles%\swipl\bin\swipl.exe"
if not defined SWIPL if exist "%ProgramFiles(x86)%\swipl\bin\swipl.exe" set "SWIPL=%ProgramFiles(x86)%\swipl\bin\swipl.exe"
if not defined SWIPL if exist "%LOCALAPPDATA%\swipl\bin\swipl.exe" set "SWIPL=%LOCALAPPDATA%\swipl\bin\swipl.exe"

if not defined SWIPL (
  echo.
  echo   SWI-Prolog was not found on this computer.
  echo.
  echo   Install it from https://www.swi-prolog.org/Download.html
  echo   or, in a Command Prompt, run:
  echo       winget install --id SWI-Prolog.SWI-Prolog
  echo.
  echo   Then run this file again.
  echo.
  pause
  exit /b 1
)

"%SWIPL%" -g start -t halt main.pl
pause
