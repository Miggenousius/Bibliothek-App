/*
  Datei: google_login.dart
  Zweck: Google-Login-Button für @kigaprima.ch-Nutzer mit Datenimport aus Google Drive
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Dieses Widget bietet einen Login-Button, mit dem sich Nutzer über Google anmelden können.
  Zugelassen sind nur E-Mail-Adressen mit der Domain @kigaprima.ch.
  Nach erfolgreichem Login wird die Drive-API initialisiert, die zentrale JSON-Datei synchronisiert
  und zur Startseite der App weitergeleitet.

  Verwendet in:
  - `startseite.dart` als Einstiegspunkt zur Bibliotheks-App
  - Authentifizierter Zugriff auf Drive-Funktionen und lokale Dateninitialisierung
*/

import 'package:bibliotheks_app/pages/bibliothek/bibliotheks_startseite.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:bibliotheks_app/services/drive_helper.dart';
import 'package:bibliotheks_app/services/google_auth_helper.dart'; // ✅ zentraler Login & Drive-Zugriff

class GoogleLoginButton extends StatefulWidget {
  @override
  _GoogleLoginButtonState createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await googleSignIn.signIn();
      if (user != null && user.email.endsWith('@kigaprima.ch')) {
        print("✅ Erfolgreich angemeldet: "+user.email);

        // 🔐 Drive-API initialisieren
        final driveApi = await googleDriveApiHolen();

        // 📁 JSON-Datei-ID suchen oder erstellen
        final fileId = await getOrCreateBibliothekJsonInOrdner(driveApi);
        await syncFromGoogleDrive(driveApi, fileId); // 🔁 Importiere Daten in Hive

        // 🚀 Weiter zur Startseite
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BibliotheksStartseite(
              userName: user.displayName ?? 'Benutzer',
              fileId: fileId,
            ),
          ),
        );
      } else {
        print("⛔ Falsche E-Mail-Adresse");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bitte nutze eine @kigaprima.ch-Adresse!")),
        );
        await googleSignIn.signOut();
      }
    } catch (e) {
      print("❌ Fehler beim Login: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Anmeldung fehlgeschlagen")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
      onPressed: _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text("Mit kigaprima-Adresse anmelden"),
    );
  }
}
