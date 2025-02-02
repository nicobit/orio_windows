import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart'; // Package for running shell commands

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("ADB Control")),
        body: ADBControlPanel(),
      ),
    );
  }
}

class ADBControlPanel extends StatefulWidget {
  const ADBControlPanel({super.key});

  @override
  _ADBControlPanelState createState() => _ADBControlPanelState();
}

class _ADBControlPanelState extends State<ADBControlPanel> with SingleTickerProviderStateMixin {
  String adbOutput = "";
  bool isDeviceConnected = false;
  bool isAdbInstalled = false;
  bool _isLoading = false; // Add this variable
  bool _isAdbOutputVisible = true; // Add this variable
  bool isSystemUpdateDisabled = false; // Add this variable
  List<AppInfo> apps = [];
  late TabController _tabController;
  String currentLanguage = ""; // Add this variable

  @override
  void initState() {
    super.initState();
    checkAdbInstallation();  // Check if ADB is installed on app startup
    _tabController = TabController(length: 4, vsync: this); // Update length to 4
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Method to run ADB command
  Future<void> runADBCommand(String command) async {
    final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
    setState(() {
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  // Method to check if ADB is installed and accessible
  Future<void> checkAdbInstallation() async {
    String command = "adb version";
    try {
      final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
      setState(() {
        // Check if adb version info is returned
        isAdbInstalled = result.stdout.toString().contains('Android Debug Bridge');
        adbOutput += "\n\$ $command\n${result.stdout.toString()}";
      });
      if (isAdbInstalled) {
        checkDeviceConnection(); // Check device connection if ADB is installed
      }
    } catch (e) {
      setState(() {
        isAdbInstalled = false;
        adbOutput += "\n\$ $command\nADB is not installed or not configured in the PATH.";
      });
    }
  }

  // Method to check ADB device connection
  Future<void> checkDeviceConnection() async {
    String command = "adb devices";
    final result = await run(command.split(' ')[0], command.split(' ').sublist(1));
   
    debugPrint(result.stdout.toString());
   
    setState(() {
      // Check if device is connected
      if (result.stdout.toString().contains('device')) {
        isDeviceConnected = true;
        listNonSystemApps(); // Load the list of apps when the device is connected
        getCurrentLanguage(); // Get the current language when the device is connected
        checkSystemUpdateStatus(); // Check system update status when the device is connected
      } else {
        isDeviceConnected = false;
        adbOutput += "\n\$ $command\nNo device connected!";
      }
    });
  }

  // Method to get the current language of the Android phone
  Future<void> getCurrentLanguage() async {
    String command = "adb shell getprop persist.sys.locale";
    final result = await run(command,[]);
    setState(() {
      currentLanguage = result.stdout.toString().trim();
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  // Method to open the locale settings
  Future<void> openLocaleSettings() async {
    String command = "adb shell am start -a android.settings.LOCALE_SETTINGS";
    await runADBCommand(command);
  }

  // Method to disable system updates
  Future<void> disableSystemUpdates() async {
    String command = "adb shell pm disable-user --user 0 com.google.android.gms";
    await runADBCommand(command);
    checkSystemUpdateStatus(); // Update the system update status after disabling it
  }

  // Method to enable system updates
  Future<void> enableSystemUpdates() async {
    String command = "adb shell pm enable com.google.android.gms";
    await runADBCommand(command);
    checkSystemUpdateStatus(); // Update the system update status after enabling it
  }

  // Method to check if system updates are disabled
  Future<void> checkSystemUpdateStatus() async {
    String command = "adb shell pm list packages -d";
    final result = await run(command, []);
    setState(() {
      isSystemUpdateDisabled = result.stdout.toString().split('\n').any((line) => line.trim() == 'package:com.google.android.gms');
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  // Method to list non-system apps
  Future<void> listNonSystemApps() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    String command = "adb shell pm list packages -3";  // List only third-party apps
    final result = await run(command.split(' ')[0], command.split(' ').sublist(1));
    List<AppInfo> appList = [];
    for (String line in result.stdout.toString().split('\n')) {
      if (line.isNotEmpty) {
        String packageName = line.split(':')[1];
        bool isEnabled = await isAppEnabled(packageName);
        appList.add(AppInfo(packageName: packageName, isEnabled: isEnabled));
      }
    }
    // Check if Google Play Store is installed
   
      bool isEnabled = await isAppEnabled("com.android.vending");
      appList.add(AppInfo(packageName: "com.android.vending", isEnabled: isEnabled));
    
    setState(() {
      apps = appList;
      _isLoading = false; // Set loading to false
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  // Method to check if an app is enabled
  Future<bool> isAppEnabled(String packageName) async {
    String command = "adb shell pm list packages -d";
    final result = await run(command.split(' ')[0], command.split(' ').sublist(1));
    return !result.stdout.toString().contains(packageName);
  }

  // Method to disable or enable a specific app
  Future<void> toggleApp(String packageName, bool enable) async {
    String command = enable
        ? "adb shell pm enable $packageName"
        : "adb shell pm disable-user --user 0 $packageName";
    //final result = await run(command.split(' ')[0], command.split(' ').sublist(1));
    final result = await run(command, []);
    setState(() {
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
      if (result.stdout.toString().contains('enabled') || result.stdout.toString().contains('disabled')) {
        apps.firstWhere((app) => app.packageName == packageName).isEnabled = enable;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ADB installation status
          Text(
            isAdbInstalled
                ? "ADB is Installed and Configured"
                : "ADB is Not Installed or Not Configured",
            style: TextStyle(fontSize: 18, color: isAdbInstalled ? Colors.green : Colors.red),
          ),
          
          // If ADB is installed and device is connected, show the other options
          if (isAdbInstalled) ...[
            // Connectivity status
            Text(
              isDeviceConnected ? "Device Connected" : "No Device Connected",
              style: TextStyle(fontSize: 18, color: isDeviceConnected ? Colors.green : Colors.red),
            ),
            
            // Button to check device connection
            ElevatedButton.icon(
              onPressed: checkDeviceConnection,
              icon: Icon(Icons.usb, color: Colors.white),
              label: Text("Check Device Connection"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            // If device is connected, show the rest of the UI options
            if (isDeviceConnected) ...[
              // TabBar with tabs
              PreferredSize(
                preferredSize: Size.fromHeight(30.0), // Set the height to the minimum possible
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: "Language"),
                    Tab(text: "Disable Updates"),
                    Tab(text: "List Apps"),
                    Tab(text: "ADB Output"), // New tab for ADB Output
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: openLocaleSettings,
                            icon: Icon(Icons.language, color: Colors.white),
                            label: Text("Open Locale Settings"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: disableSystemUpdates,
                            icon: Icon(Icons.system_update, color: Colors.white),
                            label: Text("Disable Updates"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10), // Add some space between buttons
                          ElevatedButton.icon(
                            onPressed: enableSystemUpdates,
                            icon: Icon(Icons.system_update, color: Colors.white),
                            label: Text("Enable Updates"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10), // Add some space between button and status
                          Text(
                            isSystemUpdateDisabled ? "System Updates Disabled" : "System Updates Enabled",
                            style: TextStyle(fontSize: 18, color: isSystemUpdateDisabled ? Colors.red : Colors.green),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: listNonSystemApps,
                            icon: Icon(Icons.apps, color: Colors.white),
                            label: Text("List Apps"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        // Show spinner while loading apps
                        if (_isLoading)
                          CircularProgressIndicator()
                        else
                          // Show list of non-system apps with sliders to enable/disable them
                          Expanded(
                            child: ListView.builder(
                              itemCount: apps.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  tileColor: index % 2 == 0 ? Colors.white : Colors.grey[200],
                                  title: Text(apps[index].packageName),
                                  trailing: Switch(
                                    value: apps[index].isEnabled,
                                    onChanged: (value) {
                                      toggleApp(apps[index].packageName, value);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    Column(
                      children: [
                       
                        // Show output of ADB commands
                        Visibility(
                          visible: _isAdbOutputVisible,
                          child: Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Text(
                                  "ADB Output: \n$adbOutput",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class AppInfo {
  final String packageName;
  bool isEnabled;

  AppInfo({required this.packageName, required this.isEnabled});
}
