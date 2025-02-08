# orio_windows

This projet was my second try to use Visual Studio Code and GitHub Copilot for an app I need to configure an Android Phone :

- Disabling/Enabling System Updates
- Disable / Enable Applications
- Changing the Locations

## API Key / Token

The functions in hugging_face_api retrieve the API key from the file APIKey.txt. Create it and add the key: HaggingFace inference API are used. 

It should be in the root folder of the project when debugging from Visual StudioCode. 

When executing the exe directly , it has to be on the same path of the excel.

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

# Build and create zip

Run buildAndZip.bat if you want diretly build in release mode and create the zip of it.