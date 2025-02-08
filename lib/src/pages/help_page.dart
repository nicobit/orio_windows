import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String _language = 'English';

  final Map<String, String> _instructions = {
    'English': 'To activate debug mode on an Android device:\n\n'
        '1. Open the Settings app.\n'
        '2. Scroll down and tap "About phone".\n'
        '3. Tap "Build number" seven times.\n'
        '4. Return to the previous screen to find "Developer options".\n'
        '5. Tap "Developer options" and enable "USB debugging".',
    'Italian': 'Per attivare la modalità debug su un dispositivo Android:\n\n'
        '1. Apri l\'app Impostazioni.\n'
        '2. Scorri verso il basso e tocca "Informazioni sul telefono".\n'
        '3. Tocca "Numero build" sette volte.\n'
        '4. Torna alla schermata precedente per trovare "Opzioni sviluppatore".\n'
        '5. Tocca "Opzioni sviluppatore" e abilita "Debug USB".',
    'French': 'Pour activer le mode débogage sur un appareil Android:\n\n'
        '1. Ouvrez l\'application Paramètres.\n'
        '2. Faites défiler vers le bas et appuyez sur "À propos du téléphone".\n'
        '3. Appuyez sept fois sur "Numéro de build".\n'
        '4. Revenez à l\'écran précédent pour trouver "Options pour les développeurs".\n'
        '5. Appuyez sur "Options pour les développeurs" et activez "Débogage USB".',
    'German': 'So aktivieren Sie den Debug-Modus auf einem Android-Gerät:\n\n'
        '1. Öffnen Sie die Einstellungen-App.\n'
        '2. Scrollen Sie nach unten und tippen Sie auf "Über das Telefon".\n'
        '3. Tippen Sie siebenmal auf "Build-Nummer".\n'
        '4. Kehren Sie zum vorherigen Bildschirm zurück, um "Entwickleroptionen" zu finden.\n'
        '5. Tippen Sie auf "Entwickleroptionen" und aktivieren Sie "USB-Debugging".',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _language,
              onChanged: (String? newValue) {
                setState(() {
                  _language = newValue!;
                });
              },
              items: _instructions.keys.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              _instructions[_language]!,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}