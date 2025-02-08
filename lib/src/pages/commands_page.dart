import 'package:flutter/material.dart';
import '../utilities/localizedText.dart';
import 'dart:io'; // Import dart:io for file operations
import '../utilities/adb_helper.dart';

class CommandsPage extends StatefulWidget {

  const CommandsPage({super.key});
  @override
  _CommandsPageState createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {

  List<Map<String, String>> commands = []; // Add this variable

   @override
  void initState() {
    loadCommandsFromFile();
    super.initState(); 
  }

   Future<void> saveCommandsToFile(List<Map<String, String>> commands) async {
    final file = File('commands.csv');
    final csvContent = StringBuffer();
    csvContent.writeln('commandName,command');
    for (var command in commands) {
      csvContent.writeln('${command['commandName']},${command['command']}');
    }
    await file.writeAsString(csvContent.toString());
    if(mounted){
      setState(() {
      // adbOutput += "\nCommands saved to commands.csv";
      });
    }
  }

  Future<void> loadCommandsFromFile() async {
    final file = File('commands.csv');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      final commandsN = <Map<String, String>>[];
      for (var line in lines.skip(1)) {
        final parts = line.split(',');
        if (parts.length == 2) {
          commandsN.add({'commandName': parts[0], 'command': parts[1]});
        }
      }
      if(mounted){
        setState(() {
       // adbOutput += "\nCommands loaded from commands.csv";
        commands = commandsN;
      });
      }
      
      
    } else {
      if(mounted){
        setState(() {
        //  adbOutput += "\ncommands.csv file does not exist.";
        });
      }
      
    }
  }

   @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Text(LocalizedText.get('commands')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:   Column(
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await loadCommandsFromFile();
                      },
                      icon: Icon(Icons.file_download, color: Colors.white),
                      label: Text("Load Commands"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await saveCommandsToFile(commands);
                      },
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text("Save Commands"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        String? commandName = await _showInputDialog(context, "Enter Command Name");
                        if (commandName != null && commandName.isNotEmpty) {
                          String? command = await _showInputDialog(context, "Enter Command");
                          if (command != null && command.isNotEmpty) {
                            setState(() {
                              commands.add({'commandName': commandName, 'command': command});
                            });
                            await saveCommandsToFile(commands);
                          }
                        }
                      },
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text("New"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                      ]
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: commands.length,
                        itemBuilder: (context, index) {
                            return ListTile(
                            tileColor: index % 2 == 0 ? Colors.white : Colors.grey[200],
                            title: Text(commands[index]['commandName']!),
                            subtitle: Text(commands[index]['command']!),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                              IconButton(
                                icon: Icon(Icons.play_arrow, color: Colors.green),
                                onPressed: () async {
                                await AdbHelper.runADBCommand(commands[index]['command']!);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirm Deletion'),
                                    content: Text('Are you sure you want to delete ${commands[index]['commandName']}?'),
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
                                  setState(() {
                                  commands.removeAt(index);
                                  });
                                  await saveCommandsToFile(commands);
                                }
                                },
                              ),
                              ],
                            ),
                            );
                        },
                      ),
                    ),
                  ],
                ),
    )
     );
  }
}

Future<String?> _showInputDialog(BuildContext context, String title) async {
  String input = '';
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          onChanged: (value) {
            input = value;
          },
          decoration: InputDecoration(hintText: "Enter text here"),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(input);
            },
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}