import 'package:flutter/material.dart';
import '../utilities/hugging_face_api.dart';
import '../utilities/adb_helper.dart';

class AdbAiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot'),
      ),
      body: ChatbotWidget(),
    );
  }
}

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});
  @override
  _ChatbotWidgetState createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _sendMessage();
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add({'text': _controller.text, 'color': Colors.black});
        _isLoading = true;
      });
      _sendToAi(_controller.text);
      _controller.clear();
    }
  }

  Future<void> _sendToAi(String message) async {
    HuggingFaceAPI.getAdbCommand(message).then((response) {
      setState(() {
        var text = response.commandsText.isEmpty ? "No result" : response.commandsText;
        _messages.add({'text': text, 'color': Colors.blue});
        _isLoading = false;
      });
      if (response.commands.isNotEmpty) {
        _showCommandSelectionDialog(response.commands);
      }
    }).catchError((error) {
      setState(() {
        _messages.add({'text': 'Error: $error', 'color': Colors.red});
        _isLoading = false;
      });
    });
  }

  void _showCommandSelectionDialog(List<String> commands) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select ADB Command'),
          content: SingleChildScrollView(
            child: ListBody(
              children: commands.map((command) {
                return ListTile(
                  title: Text(command),
                  onTap: () {
                    Navigator.of(context).pop();
                    RunADBCommand(command);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
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

  Future<void> RunADBCommand(String command) async {
    var isDeviceConnected = await AdbHelper.checkDeviceConnection();
    if (isDeviceConnected) {
      final result = await AdbHelper.runADBCommand(command);
      var message = "Command: $command\n";
      var commandResult = result.exitCode == 0 ? result.stdout : result.stderr;
      message += "Result: $commandResult";
      setState(() {
        _messages.add({'text': message, 'color': Colors.green});
        _isLoading = false;
      });
    } else {
      setState(() {
        _messages.add({'text': "Device not connected", 'color': Colors.red});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: SelectableText(
                  _messages[index]['text'],
                  style: TextStyle(color: _messages[index]['color']),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                  ),
                  onSubmitted: (value) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}