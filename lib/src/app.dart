import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:io'; // Import dart:io for file operations

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
  bool isDeviceConnected = true;
  bool isAdbInstalled = false;
  bool _isLoading = false;
  final bool _isAdbOutputVisible = true;
  bool isSystemUpdateDisabled = false;
  List<AppInfo> apps = [];
  List<AppInfo> filteredApps = [];
  late TabController _tabController;
  String currentLanguage = "";
  Set<String> selectedApps = {}; // Add this variable
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String selectedLanguage = 'English';

  final Map<String, Map<String, String>> buttonTexts = {
    'English': {
      'checkDeviceConnection': 'Check Device Connection',
      'openLocaleSettings': 'Open Locale Settings',
      'disableUpdates': 'Disable Updates',
      'enableUpdates': 'Enable Updates',
      'listApps': 'List Apps',
      'saveSelectedApps': 'Save Selected Apps',
      'disableSelected': 'Disable Selected',
      'deleteSelected': 'Delete Selected',
      'languageTab': 'Language',
      'disableUpdatesTab': 'Disable Updates',
      'listAppsTab': 'List Apps',
      'adbOutputTab': 'ADB Output',
    },
    'French': {
      'checkDeviceConnection': 'Vérifier la connexion de l\'appareil',
      'openLocaleSettings': 'Ouvrir les paramètres de langue',
      'disableUpdates': 'Désactiver les mises à jour',
      'enableUpdates': 'Activer les mises à jour',
      'listApps': 'Lister les applications',
      'saveSelectedApps': 'Enregistrer les applications sélectionnées',
      'disableSelected': 'Désactiver les sélectionnés',
      'deleteSelected': 'Supprimer les sélectionnés',
      'languageTab': 'Langue',
      'disableUpdatesTab': 'Désactiver les mises à jour',
      'listAppsTab': 'Lister les applications',
      'adbOutputTab': 'Sortie ADB',
    },
    'German': {
      'checkDeviceConnection': 'Geräteverbindung prüfen',
      'openLocaleSettings': 'Spracheinstellungen öffnen',
      'disableUpdates': 'Updates deaktivieren',
      'enableUpdates': 'Updates aktivieren',
      'listApps': 'Apps auflisten',
      'saveSelectedApps': 'Ausgewählte Apps speichern',
      'disableSelected': 'Ausgewählte deaktivieren',
      'deleteSelected': 'Ausgewählte löschen',
      'languageTab': 'Sprache',
      'disableUpdatesTab': 'Updates deaktivieren',
      'listAppsTab': 'Apps auflisten',
      'adbOutputTab': 'ADB-Ausgabe',
    },
    'Italian': {
      'checkDeviceConnection': 'Controlla connessione dispositivo',
      'openLocaleSettings': 'Apri impostazioni lingua',
      'disableUpdates': 'Disabilita aggiornamenti',
      'enableUpdates': 'Abilita aggiornamenti',
      'listApps': 'Elenca app',
      'saveSelectedApps': 'Salva app selezionate',
      'disableSelected': 'Disabilita selezionati',
      'deleteSelected': 'Elimina selezionati',
      'languageTab': 'Lingua',
      'disableUpdatesTab': 'Disabilita aggiornamenti',
      'listAppsTab': 'Elenca app',
      'adbOutputTab': 'Output ADB',
    },
  };

  @override
  void initState() {
    super.initState();
    checkAdbInstallation();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      filteredApps = apps.where((app) => app.packageName.contains(_searchQuery)).toList();
    });
  }

  Future<void> runADBCommand(String command) async {
    final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
    setState(() {
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  Future<void> checkAdbInstallation() async {
    String command = "adb version";
    try {
      final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
      setState(() {
        isAdbInstalled = result.stdout.toString().contains('Android Debug Bridge');
        adbOutput += "\n\$ $command\n${result.stdout.toString()}";
      });
      if (isAdbInstalled) {
        checkDeviceConnection();
      }
    } catch (e) {
      setState(() {
        isAdbInstalled = false;
        adbOutput += "\n\$ $command\nADB is not installed or not configured in the PATH.";
      });
    }
  }

  Future<void> checkDeviceConnection() async {
    String command = "adb devices";
    final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
    debugPrint(result.stdout.toString());
    setState(() {
      List<String> lines = result.stdout.toString().split('\n');
      if (lines.length > 1 && lines[1].trim().isNotEmpty) {
        isDeviceConnected = true;
        listNonSystemApps();
        getCurrentLanguage();
        checkSystemUpdateStatus();
      } else {
        isDeviceConnected = true;
        adbOutput += "\n\$ $command\nNo device connected!";
      }
    });
  }

  Future<void> getCurrentLanguage() async {
    String command = "adb shell getprop persist.sys.locale";
    final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
    setState(() {
      currentLanguage = result.stdout.toString().trim();
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  Future<void> openLocaleSettings() async {
    String command = "adb shell am start -a android.settings.LOCALE_SETTINGS";
    await runADBCommand(command);
  }

  Future<void> disableSystemUpdates() async {
    String command = "adb shell pm disable-user --user 0 com.google.android.gms";
    await runADBCommand(command);
    checkSystemUpdateStatus();
  }

  Future<void> enableSystemUpdates() async {
    String command = "adb shell pm enable com.google.android.gms";
    await runADBCommand(command);
    checkSystemUpdateStatus();
  }

  Future<void> checkSystemUpdateStatus() async {
    String command = "adb shell pm list packages -d";
    final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
    setState(() {
      isSystemUpdateDisabled = result.stdout.toString().split('\n').any((line) => line.trim() == 'package:com.google.android.gms');
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  Future<void> listNonSystemApps() async {
    setState(() {
      _isLoading = true;
    });
    String command = "adb shell pm list packages -3"; // add -3 to retrieve not system update
    final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
    List<AppInfo> appList = [];
    for (String line in result.stdout.toString().split('\n')) {
      if (line.isNotEmpty) {
        String packageName = line.split(':')[1].toString().trim();
        bool isEnabled = await isAppEnabled(packageName);
        appList.add(AppInfo(packageName: packageName, isEnabled: isEnabled));
      }
    }
    bool isEnabled = await isAppEnabled("com.android.vending");
    appList.add(AppInfo(packageName: "com.android.vending", isEnabled: isEnabled));
    await loadSelectedApps(); // Load selected apps from file
    setState(() {
      apps = appList;
      filteredApps = appList;
      _isLoading = false;
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
    });
  }

  Future<bool> isAppEnabled(String packageName) async {
    String command = "adb shell pm list packages -d";
    final result = await run(command.split(' ')[0], command.split(' ').sublist(1));
    return !result.stdout.toString().contains(packageName);
  }

  Future<void> toggleApp(String packageName, bool enable) async {
    String command = enable
        ? "adb shell pm enable $packageName"
        : "adb shell pm disable-user --user 0 $packageName";
    final result = await run(command, []);
    setState(() {
      adbOutput += "\n\$ $command\n${result.stdout.toString()}";
      if (result.stdout.toString().contains('enabled') || result.stdout.toString().contains('disabled')) {
        if (apps.any((app) => app.packageName == packageName)) {
          apps.firstWhere((app) => app.packageName == packageName).isEnabled = enable;
        }
      }
    });
  }

  Future<void> saveSelectedApps() async {
    final file = File('packagesToDisable.txt');
    await file.writeAsString(selectedApps.join('\n'));
    setState(() {
      adbOutput += "\nSelected apps saved to packagesToDisable.txt";
    });
  }

  Future<void> loadSelectedApps() async {
    final file = File('packagesToDisable.txt');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      setState(() {
        selectedApps = lines.toSet();
        adbOutput += "\nContent of packagesToDisable.txt:\n${lines.join('\n')}";
      });
    }
  }

  Future<void> disableSelectedApps() async {
    for (String packageName in selectedApps) {
      await toggleApp(packageName, false);
    }
  }

  Future<void> deleteSelectedApps() async {
    for (String packageName in selectedApps) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete $packageName?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete'),
              ),
            ],
          );
        },
      );
      if (confirm == true) {
        String command = "adb uninstall $packageName";
        await runADBCommand(command);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: selectedLanguage,
            onChanged: (String? newValue) {
              setState(() {
                selectedLanguage = newValue!;
              });
            },
            items: buttonTexts.keys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Text(
            isAdbInstalled
                ? "ADB is Installed and Configured"
                : "ADB is Not Installed or Not Configured",
            style: TextStyle(fontSize: 18, color: isAdbInstalled ? Colors.green : Colors.red),
          ),
          if (isAdbInstalled) ...[
            Text(
              isDeviceConnected ? "Device Connected" : "No Device Connected",
              style: TextStyle(fontSize: 18, color: isDeviceConnected ? Colors.green : Colors.red),
            ),
            ElevatedButton.icon(
              onPressed: checkDeviceConnection,
              icon: Icon(Icons.usb, color: Colors.white),
              label: Text(buttonTexts[selectedLanguage]!['checkDeviceConnection']!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            if (isDeviceConnected) ...[
              PreferredSize(
                preferredSize: Size.fromHeight(30.0),
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: buttonTexts[selectedLanguage]!['languageTab']!),
                    Tab(text: buttonTexts[selectedLanguage]!['disableUpdatesTab']!),
                    Tab(text: buttonTexts[selectedLanguage]!['listAppsTab']!),
                    Tab(text: buttonTexts[selectedLanguage]!['adbOutputTab']!),
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
                            label: Text(buttonTexts[selectedLanguage]!['openLocaleSettings']!),
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
                            label: Text(buttonTexts[selectedLanguage]!['disableUpdates']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: enableSystemUpdates,
                            icon: Icon(Icons.system_update, color: Colors.white),
                            label: Text(buttonTexts[selectedLanguage]!['enableUpdates']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            isSystemUpdateDisabled ? "System Updates Disabled" : "System Updates Enabled",
                            style: TextStyle(fontSize: 18, color: isSystemUpdateDisabled ? Colors.red : Colors.green),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: listNonSystemApps,
                              icon: Icon(Icons.apps, color: Colors.white),
                              label: Text(buttonTexts[selectedLanguage]!['listApps']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: saveSelectedApps,
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text(buttonTexts[selectedLanguage]!['saveSelectedApps']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: disableSelectedApps,
                              icon: Icon(Icons.delete_sweep, color: Colors.white),
                              label: Text(buttonTexts[selectedLanguage]!['disableSelected']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: deleteSelectedApps,
                              icon: Icon(Icons.delete, color: Colors.white),
                              label: Text(buttonTexts[selectedLanguage]!['deleteSelected']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: "Search Apps",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (_isLoading)
                          CircularProgressIndicator()
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredApps.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  tileColor: index % 2 == 0 ? Colors.white : Colors.grey[200],
                                  leading: Checkbox(
                                    value: selectedApps.contains(filteredApps[index].packageName),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedApps.add(filteredApps[index].packageName);
                                        } else {
                                          selectedApps.remove(filteredApps[index].packageName);
                                        }
                                      });
                                    },
                                  ),
                                  title: Text(filteredApps[index].packageName),
                                  trailing: Switch(
                                    value: filteredApps[index].isEnabled,
                                    onChanged: (value) {
                                      toggleApp(filteredApps[index].packageName, value);
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
                        Visibility(
                          visible: _isAdbOutputVisible,
                          child: Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: SelectableText(
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
