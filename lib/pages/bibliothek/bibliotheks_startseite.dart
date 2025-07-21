/*
  Datei: bibliotheks_startseite.dart
  Zweck: Startseite der Bibliotheks-App mit Begrüssung, Navigation zu Suche und Upload
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Datei enthält die Startseite nach erfolgreichem Login.
  Sie zeigt eine personalisierte Begrüssung mit Hintergrundbild und zwei Buttons:
  - „Bibliotheksartikel ausleihen“ führt zur Suchseite
  - „Bibliotheksartikel hinzufügen“ führt zum Upload-Formular

  Verwendet in:
  - Hauptnavigation nach erfolgreichem Google-Login
  - App-Einstiegspunkt für Nutzerinteraktionen
*/


import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../artikel/bibliothek_formular_erstellen.dart';
import '../suche/suchseite.dart';
import 'package:bibliotheks_app/pages/meine_artikel/meine_pdfs_und_qrcodes.dart';
import 'package:bibliotheks_app/services/drive_helper.dart'; // Stelle sicher, dass diese Datei die Funktion `syncFromGoogleDrive` enthält.

class BibliotheksStartseite extends StatelessWidget {
  final String userName;
  final String fileId;

  const BibliotheksStartseite({
    Key? key,
    required this.userName,
    required this.fileId,
  }) : super(key: key);

  Future<void> _triggerSync(BuildContext context) async {
    try {
      var user = await GoogleSignIn().signInSilently();
      if (user == null) {
        // Fallback: Nutzer auffordern, sich erneut anzumelden
        user = await GoogleSignIn().signIn();
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Nicht angemeldet.")),
          );
          return;
        }
      }

      final authHeaders = await user.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      await syncFromGoogleDrive(driveApi, fileId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Synchronisation erfolgreich!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Fehler bei der Synchronisation: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kigaprima-Bibliothek'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _triggerSync(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/hintergrundbild.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Willkommen, $userName!',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Suchseite()),
                        );
                      },
                      child: const Text('Bibliotheksartikel ausleihen'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BibliothekFormularErstellen()),
                        );
                      },
                      child: const Text('Bibliotheksartikel hinzufügen'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MeinePdfsUndQrcodesSeite()),
                        );
                      },
                      child: const Text('Meine PDFs & QR-Codes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}