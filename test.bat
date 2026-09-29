@echo off
REM ====================================================================
REM  DengueTriage-ES  --  run the automated test suite (Windows)
REM ====================================================================
setlocal
cd /d "%~dp0"

set "SWIPL="
where swipl >nul 2>nul && set "SWIPL=swipl"
if not defined SWIPL if exist "%ProgramFiles%\swipl\bin\swipl.exe" set "SWIPL=%ProgramFiles%\swipl\bin\swipl.exe"
if not defined SWIPL if exist "%ProgramFiles(x86)%\swipl\bin\swipl.exe" set "SWIPL=%ProgramFiles(x86)%\swipl\bin\swipl.exe"
if not defined SWIPL if exist "%LOCALAPPDATA%\swipl\bin\swipl.exe" set "SWIPL=%LOCALAPPDATA%\swipl\bin\swipl.exe"

if not defined SWIPL (
  echo   SWI-Prolog was not found. See run.bat for installation notes.
  pause
  exit /b 1
)

"%SWIPL%" -g run_tests -t halt main.pl
pause
