import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class HuggingFaceAPI {
  static const String apiUrl = "https://api-inference.huggingface.co/models/meta-llama/Meta-Llama-3-8B-Instruct";
  static const String apiKeyFilePath = "apikey.txt"; // Replace with your file path

  static Future<String> _readApiKeyFromFile() async {
    try {
      final file = File(apiKeyFilePath);
      return await file.readAsString();
    } catch (e) {
      throw Exception("Error reading API key from file: $e");
    }
  }

  static Future<ADBCommandResult> getAdbCommand(String userRequest) async {
    ADBCommandResult retval = ADBCommandResult(
      isSuccess: false,
      commands: [],
      message: "No response generated.",
      commandsText: "",
    );
    const int maxRetries = 3;
    int retries = 0;
    userRequest = "Convert the following request in ADB ( android debug bridge ) command ( it will be used to execute from the PC to the phone connected by phone): $userRequest";

    while (retries < maxRetries) {
      try {
        final apiKey = await _readApiKeyFromFile();
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "inputs": userRequest, // Input text for the model
            "wait_for_model": true, // Wait for the model to load
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          var result = data[0]["generated_text"] ?? "No response generated.";
          result = parse(result).documentElement?.text ?? "";
          var commands = getADBCommands(result);
          retval.commandsText = commands['mergedCommands'];
          retval.commands = commands['commands'];
          retval.isSuccess = true;
          retval.message = result;

          return retval;
        } else if (response.statusCode == 503) {
          // If the model is still loading, retry after a delay
          print("Model is still loading, retrying...");
          retries++;
          await Future.delayed(Duration(seconds: 10)); // Wait 10 seconds before retrying
        } else {
          retval.isSuccess = false;
          retval.message = "Error: ${response.statusCode} - ${response.body}";
          return retval;
        }
      } catch (e) {
        retval.isSuccess = false;
        retval.message = "Error: $e";
        return retval;
      }
    }
    retval.isSuccess = false;
    retval.message = "Model could not be loaded after $maxRetries retries.";
    return retval;
  }
}

class ADBCommandResult {
  bool isSuccess;
  List<String> commands;
  String commandsText;
  String message;

  ADBCommandResult({
    required this.isSuccess,
    required this.commands,
    required this.message,
    required this.commandsText,
  });
}

Map<String, dynamic> getADBCommands(String inputText) {
  // Define the regex pattern to match any line starting with 'adb'
  final regex = RegExp(r'^adb.*', multiLine: true);

  // Find all matches in the input text
  Iterable<RegExpMatch> matches = regex.allMatches(inputText);

  // Create a list to store the matched ADB commands
  List<String> adbCommands = [];

  // Loop through all matches and add the command to the list
  for (var match in matches) {
    adbCommands.add(match.group(0)!);
  }

  // Join all commands into a single string separated by a newline
  String mergedCommands = adbCommands.join('\n');

  // Return both the list of commands and the merged string in a map
  return {
    'commands': adbCommands,
    'mergedCommands': mergedCommands,
  };
}