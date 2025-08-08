/*
  Datei: startseite.dart
  Zweck: Einstiegsseite der Bibliotheks-App mit Begrüssungstext, Logo und Google-Login
  Autor: Michi Zumbrunnen
  Letzte Änderung: 08. August 2025

  Beschreibung:
  Diese Datei enthält die Startseite der App, die nach dem Start angezeigt wird.
  Sie zeigt das App-Logo, einen Begrüssungstext mit Hinweis auf die Nutzung
  innerhalb der Schule Arlesheim sowie den Login-Button für @kigaprima.ch-Nutzer.
  Zusätzlich gibt es einen Button "Weiter ohne Login", um direkt zur Bibliotheksstartseite
  zu gelangen – nützlich für Tests oder Web-Zugriff ohne Google OAuth.
*/

import 'package:flutter/material.dart';
import '../../widgets/google_login.dart';
import '../bibliothek/bibliotheks_startseite.dart';

class Startseite extends StatefulWidget {
  const Startseite({super.key});

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
                "Diese App ist für die interne Schulbibliothek von Arlesheim. "
                    "Du findest darin die Bücher und Objekte der Lehrpersonenbibliothek, "
                    "des Anschauungsmaterials und der Materialien von privaten Personen.\n\n"
                    "Bitte melde dich mit deiner @kigaprima.ch-Adresse an oder fahre ohne Login fort.",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Google Login Button
              GoogleLoginButton(),

              const SizedBox(height: 15),

              // Weiter-ohne-Login-Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BibliotheksStartseite(
                        userName: 'Gast', // Platzhaltername
                        fileId: 'none',   // Platzhalter-Datei-ID
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Weiter ohne Login',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
