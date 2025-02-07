@echo off
setlocal enabledelayedexpansion

:: Set paths
set "SOURCE_FOLDER=build\windows\x64\runner\Release"  REM Flutter Windows build output folder
set "RELATIVE_DEST_FOLDER=dist"

:: Convert relative path to absolute path
for /f "delims=" %%I in ('powershell -Command "Resolve-Path '%CD%\%RELATIVE_DEST_FOLDER%'"') do set "DESTINATION_FOLDER=%%I"


:: Set version manually (or use auto-generated version)
set "VERSION=1.0"

:: Auto-generate version based on date-time (YYYYMMDD_HHMMSS) if needed
:: Uncomment the following lines to enable auto-versioning
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
    set "VERSION=%datetime:~0,8%_%datetime:~8,6%"

:: Define ZIP file name with version
set "ZIP_NAME=orio_windows_v%VERSION%.zip"

:: Run Flutter build for Windows and WAIT for completion
echo Running Flutter build for Windows...
call flutter build windows
:: Alternative if call doesn't work:
:: start /wait flutter build windows

:: Check if Flutter build was successful
if %errorlevel% neq 0 (
    echo Flutter build failed! Exiting...
    exit /b %errorlevel%
)

echo Flutter build completed successfully.

:: Ensure the destination folder exists
if not exist "%DESTINATION_FOLDER%" mkdir "%DESTINATION_FOLDER%"

:: Create ZIP archive using tar (Windows 10+)
echo Creating ZIP archive...

:: Navigate to the build directory to zip everything correctly
pushd "%SOURCE_FOLDER%"
::tar -a -c -f "..\..\..\%DESTINATION_FOLDER%\%ZIP_NAME%" *
tar -a -c -f "%DESTINATION_FOLDER%\%ZIP_NAME%" *
popd

:: Check if the ZIP was created successfully
if exist "%DESTINATION_FOLDER%\%ZIP_NAME%" (
    echo ZIP created successfully: %DESTINATION_FOLDER%\%ZIP_NAME%
) else (
    echo ZIP creation failed!
    exit /b 1
)

echo Process completed successfully.
endlocal
pause

