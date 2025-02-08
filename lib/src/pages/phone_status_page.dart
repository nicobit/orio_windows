import 'package:flutter/material.dart';
import 'package:orio_windows/src/utilities/adb_helper.dart';
import '../utilities/localizedText.dart';

class PhoneStatusPage extends StatefulWidget {
  const PhoneStatusPage({super.key});
  @override
  _PhoneStatusState createState() => _PhoneStatusState();
}

class _PhoneStatusState extends State<PhoneStatusPage> {
  bool isSystemUpdateDisabled = false;

  @override
  void initState() {
    super.initState();
    checkSystemUpdateStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizedText.get('phonestatus')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: openLocaleSettings,
              icon: Icon(Icons.language, color: Colors.white),
              label: Text(LocalizedText.get('openLocaleSettings')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  LocalizedText.get('systemUpdates'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isSystemUpdateDisabled,
                  onChanged: (value) {
                    if (value) {
                      disableSystemUpdates();
                    } else {
                      enableSystemUpdates();
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              isSystemUpdateDisabled ? "System Updates Disabled" : "System Updates Enabled",
              style: TextStyle(
                fontSize: 18,
                color: isSystemUpdateDisabled ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openLocaleSettings() async {
    String command = "adb shell am start -a android.settings.LOCALE_SETTINGS";
    await AdbHelper.runADBCommand(command);
  }

  Future<void> disableSystemUpdates() async {
    String command = "adb shell pm disable-user --user 0 com.google.android.gms";
    await AdbHelper.runADBCommand(command);
    checkSystemUpdateStatus();
  }

  Future<void> enableSystemUpdates() async {
    String command = "adb shell pm enable com.google.android.gms";
    await AdbHelper.runADBCommand(command);
    checkSystemUpdateStatus();
  }

  Future<void> checkSystemUpdateStatus() async {
    String command = "adb shell pm list packages -d";
    final result = await AdbHelper.runADBCommand(command);
    if(mounted){
      setState(() {
        isSystemUpdateDisabled = !result.stdout.toString().split('\n').any((line) => line.trim() == 'package:com.google.android.gms');
      });
    }
  }
}
