# orio_windows

This projet was my second try to use Visual Studio Code and GitHub Copilot for an app I need to configure an Android Phone :

- Disabling/Enabling System Updates
- Disable / Enable Applications
- Changing the Locations

## How to build a release version

 ### Enable Windows Support in Flutter
If you haven't already enabled Windows support, run:

```
bash 

flutter config --enable-windows-desktop

```

###  Ensure Dependencies Are Installed
Make sure you have all necessary dependencies by running:

```
bash

flutter doctor
```

Check that there are no errors under "Windows Desktop".

###  Build the Release Version
Navigate to your Flutter project directory and run:

```
bash

flutter build windows
```
This will generate a release build in:

```
your_project/build/windows/runner/Release/

```
### Locate the Executable
After the build process is complete, your .exe file will be available at:

```
bash

build/windows/runner/Release/your_app.exe

```