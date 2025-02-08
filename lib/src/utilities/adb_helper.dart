import 'dart:io';

import 'package:process_run/process_run.dart';

class AdbHelper {
 

  static Future<ProcessResult> runADBCommand(String command) async {
    final result = await runExecutableArguments(command.split(' ')[0], command.split(' ').sublist(1));
    return result;
  }

   static Future<bool> checkDeviceConnection() async {

    bool retval = false;
    String command = "adb devices";
    final result = await AdbHelper.runADBCommand(command);
    
    
      List<String> lines = result.stdout.toString().split('\n');
      if (lines.length > 1 && lines[1].trim().isNotEmpty) {
        retval = true;
    }

    return retval;
  }

 
}