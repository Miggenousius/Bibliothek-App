/*
  Datei: startseite.dart
  Zweck: Einstiegsseite der Bibliotheks-App mit Begrüssungstext, Logo und Google-Login
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Datei enthält die Startseite der App, die nach dem Start angezeigt wird.
  Sie zeigt das App-Logo, einen Begrüssungstext mit Hinweis auf die Nutzung
  innerhalb der Schule Arlesheim sowie den Login-Button für @kigaprima.ch-Nutzer.

  Verwendet in:
  - App-Startpunkt (`main.dart`)
  - Nutzerführung zum Login-Prozess via Google OAuth
*/


import 'package:flutter/material.dart';
import '../../widgets/google_login.dart';

class Startseite extends StatefulWidget {
  @override
  _StartseiteState createState() => _StartseiteState();
}

class _StartseiteState extends State<Startseite> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Willkommen zur Schulbibliothek')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                "Diese App ist für die interne Schulbibliothek von Arlesheim. Du findest darin die Bücher und Objekte der Lehrpersonenbibliothek, des Anschauungsmaterials und der Materialien von privaten Personen.\n\nBitte melde dich mit deiner @kigaprima.ch-Adresse an.",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              GoogleLoginButton(),
            ],
          ),
        ),
      ),
    );
  }
}
