import 'package:flutter/material.dart';
import 'pages/applicationList.dart';
import 'pages/settings_page.dart';
import 'pages/commands_page.dart';
import 'pages/help_page.dart';
import 'pages/adb_ai_page.dart';
import 'pages/phone_status_page.dart';
import 'utilities/localizedText.dart';
import 'utilities/adb_helper.dart';


void main() {
  runApp(MyApp1());
}

class MyApp1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AdminPage(),
    );
  }
}

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  bool isDeviceConnected = false;

  static const List<Widget> _pages = <Widget>[
   Center(child: Text('Dashboard', style: TextStyle(fontSize: 24))),
    Center(child: ApplicationList()),
    Center(child: PhoneStatusPage()),
    Center(child: CommandsPage()),
    Center(child: SettingsPage()),
    Center(child: ChatbotWidget()),
    Center(child: HelpPage()),
  ];

  List<Widget> _pagesWithHelp = <Widget>[
     Center(child: ChatbotWidget()),
      Center(child: HelpPage()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> checkDeviceConnection() async {
    String command = "adb devices";
    final result = await AdbHelper.runADBCommand(command);
    debugPrint(result.stdout.toString());
    setState(() {
      List<String> lines = result.stdout.toString().split('\n');
      if (lines.length > 1 && lines[1].trim().isNotEmpty) {
        isDeviceConnected = true;
        _pagesWithHelp = <Widget>[
          Center(child: Text('Dashboard', style: TextStyle(fontSize: 24))),
          Center(child: ApplicationList()),
          Center(child: PhoneStatusPage()),
          Center(child: CommandsPage()),
          Center(child: SettingsPage()),
          Center(child: ChatbotWidget()),
          Center(child: HelpPage()),
        ];
      } else {
        isDeviceConnected = false;
        _pagesWithHelp = <Widget>[
          Center(child: ChatbotWidget()),
          Center(child: HelpPage()),
        ];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkDeviceConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        actions: [
          IconButton(
            icon: Icon(
              isDeviceConnected ? Icons.usb : Icons.usb_off,
              color: isDeviceConnected ? Colors.green : Colors.red,
            ),
            onPressed: checkDeviceConnection,
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.selected,
            destinations: [
              if (isDeviceConnected)
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  selectedIcon: Icon(Icons.dashboard, color: Colors.blue),
                  label: Text(LocalizedText.get('dashboard')),
                ),
              if (isDeviceConnected)
                NavigationRailDestination(
                  icon: Icon(Icons.apps),
                  selectedIcon: Icon(Icons.apps, color: Colors.blue),
                  label: Text(LocalizedText.get('applications')),
                ),
              if (isDeviceConnected)
                NavigationRailDestination(
                  icon: Icon(Icons.tablet_android),
                  selectedIcon: Icon(Icons.tablet_android, color: Colors.blue),
                  label: Text(LocalizedText.get('phonestatus')),
                ),
              if (isDeviceConnected)
                NavigationRailDestination(
                  icon: Icon(Icons.flash_on_sharp),
                  selectedIcon: Icon(Icons.flash_on_sharp, color: Colors.blue),
                  label: Text(LocalizedText.get('commands')),
                ),
              if (isDeviceConnected)
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  selectedIcon: Icon(Icons.settings, color: Colors.blue),
                  label: Text(LocalizedText.get('settings')),
                ),
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                selectedIcon: Icon(Icons.chat, color: Colors.blue),
                label: Text(LocalizedText.get('aichat')),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.help),
                selectedIcon: Icon(Icons.help, color: Colors.blue),
                label: Text(LocalizedText.get('help')),
              ),
            ],
          ),
          Expanded(
            child: isDeviceConnected ? _pages[_selectedIndex] : _pagesWithHelp[_selectedIndex],
          ),
        ],
      ),
    );
  }
}