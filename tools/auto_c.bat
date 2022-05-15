@echo off
setlocal enableDelayedExpansion
setlocal enableExtensions

:: Clear out any gsc, zip, and tmp/ files from previous runs.
del *.gsc /s /f /q > nul 2>&1
del *.zip /s /f /q > nul 2>&1
del /f /s /q tmp > nul
rd /s /q tmp > nul

mkdir tmp
:: Set variables.
set "crt_dir=%~dp0"
for %%I in ("%crt_dir%\..") do set "root=%%~fI"
set "SEARCHPATH=%root%\src"
set FileName=%1

:: Copy everything from ./src into %cd%
robocopy %SEARCHPATH% %cd%\tmp\ /s /e > nul

echo %cd%
gsc-tool.exe comp t6 %cd%\tmp\ > nul

robocopy %cd%\tmp\gsc\ %LOCALAPPDATA%\Plutonium\storage\t6\scripts\zm\ /s /e > nul

echo - Compiled GSC.