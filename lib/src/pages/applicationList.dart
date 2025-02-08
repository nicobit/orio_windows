
import 'package:flutter/material.dart';
import 'dart:io'; // Import dart:io for file operations
import '../utilities/adb_helper.dart';
import '../utilities/utilities.dart';
import '../utilities/localizedText.dart';


class ApplicationList extends StatefulWidget {
  const ApplicationList({super.key});

  @override
  _ApplicationListState createState() => _ApplicationListState();
}

class _ApplicationListState extends State<ApplicationList> with SingleTickerProviderStateMixin {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<AppInfo> filteredApps = [];
  List<AppInfo> apps = [];
  bool _isLoading = false;
  String _disabledApps = "";
  Set<String> selectedApps = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
     listNonSystemApps();
  }

  void _onSearchChanged() {
    if(mounted){
      setState(() {
        _searchQuery = _searchController.text;
        filteredApps = apps.where((app) => app.packageName.contains(_searchQuery)).toList();
      });
    }
  }

   Future<void> listNonSystemApps() async {
    setState(() {
      _isLoading = true;
    });
    String command = "adb shell pm list packages"; // add -3 to retrieve not system update
    final result = await AdbHelper.runADBCommand(command);
    List<AppInfo> appList = [];
    _disabledApps = "";
    for (String line in result.stdout.toString().split('\n')) {
      if (line.isNotEmpty) {
        String packageName = line.split(':')[1].toString().trim();
        bool isEnabled = await isAppEnabled(packageName);
        appList.add(AppInfo(packageName: packageName, isEnabled: isEnabled));
      }
    }
   // bool isEnabled = await isAppEnabled("com.android.vending");
    //appList.add(AppInfo(packageName: "com.android.vending", isEnabled: isEnabled));
    await loadSelectedApps(); // Load selected apps from file
    if (mounted) {
      setState(() {
        apps = appList;
        filteredApps = appList;
        _isLoading = false;
        //adbOutput += "\n\$ $command\n${result.stdout.toString()}";
      });
    }
  }

   Future<bool> isAppEnabled(String packageName) async {
    if(_disabledApps == "") {
      String command = "adb shell pm list packages -d";
      final result = await AdbHelper.runADBCommand(command);
      _disabledApps = result.stdout.toString();
    }
   
    return _disabledApps.contains(packageName);
  }

    Future<void> loadSelectedApps() async {
    final file = File('packagesToDisable.txt');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      if(mounted){
        setState(() {
          selectedApps = lines.toSet();
          //adbOutput += "\nContent of packagesToDisable.txt:\n${lines.join('\n')}";
        });
      }
    }
  }

  
  Future<void> saveSelectedApps() async {
    final file = File('packagesToDisable.txt');
    await file.writeAsString(selectedApps.join('\n'));
     if(mounted){
      setState(() {
        //adbOutput += "\nSelected apps saved to packagesToDisable.txt";
      });
     }
  }

    Future<void> deleteSelectedApps() async {
    for (String packageName in selectedApps) {
      deleteApp(packageName);
    }
  }

  Future<void> deleteApp(String packageName) async {

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
         await AdbHelper.runADBCommand(command);
      }
    
  }

   Future<void> disableSelectedApps() async {
    for (String packageName in selectedApps) {
      await toggleApp(packageName, false);
    }
  }

   Future<void> toggleApp(String packageName, bool enable) async {
    String command = enable
        ? "adb shell pm enable $packageName"
        : "adb shell pm disable-user --user 0 $packageName";
    final result = await AdbHelper.runADBCommand(command);
    if(mounted){
      setState(() {
        //adbOutput += "\n\$ $command\n${result.stdout.toString()}";
        if (result.stdout.toString().contains('enabled') || result.stdout.toString().contains('disabled')) {
          if (apps.any((app) => app.packageName == packageName)) {
            apps.firstWhere((app) => app.packageName == packageName).isEnabled = enable;
          }
        }
      });
   }
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
        title: Text(LocalizedText.get('applicationlist')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:   Column(
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                      ElevatedButton.icon(
                        onPressed: listNonSystemApps,
                        icon: Icon(Icons.apps, color: Colors.white),
                        label: Text(LocalizedText.get('listApps')),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: saveSelectedApps,
                        icon: Icon(Icons.save, color: Colors.white),
                        label: Text(LocalizedText.get('saveSelectedApps')),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: disableSelectedApps,
                        icon: Icon(Icons.delete_sweep, color: Colors.white),
                        label: Text(LocalizedText.get('disableSelected')),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: deleteSelectedApps,
                        icon: Icon(Icons.delete, color: Colors.white),
                        label: Text(LocalizedText.get('deleteSelected')),
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
                        trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                          value: filteredApps[index].isEnabled,
                          onChanged: (value) {
                          toggleApp(filteredApps[index].packageName, value);
                          },
                          ),
                          IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                          deleteApp(filteredApps[index].packageName);
                          },
                          ),
                        ],
                        ),
                        );
                        },
                      ),
                      ),
                    ],
                  )
   )
   );
  }

  @override
  void dispose() { 
    _searchController.dispose();
    super.dispose();
  }

}

class AppInfo {
  final String packageName;
  bool isEnabled;

  AppInfo({required this.packageName, required this.isEnabled});
}