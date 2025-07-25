/*
  Datei: google_auth_helper.dart
  Zweck: Authentifizierung und Zugriff auf die Google Drive API
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Datei definiert:
  - die Google Sign-In Konfiguration mit OAuth-Scopes
  - eine Funktion zur stillen Anmeldung
  - eine Methode (`googleDriveApiHolen`), die eine authentifizierte
    `DriveApi`-Instanz zurückgibt und mit gültigem Token arbeitet

  Verwendet in:
  - `upload_to_drive.dart`, `drive_helper.dart`, `ausleihe_service.dart`
  - allen Funktionen mit Zugriff auf Google Drive
*/


import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In Konfiguration mit benötigten Scopes
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/drive', // 🔁 vollständiger Zugriff
  ],
);

/// Gibt eine authentifizierte Google Drive API-Instanz zurück
Future<drive.DriveApi> googleDriveApiHolen() async {
  final user = await googleSignIn.signInSilently();
  if (user == null) throw Exception('❌ Kein Benutzer angemeldet.');

  final authHeaders = await user.authHeaders;
  final accessToken = authHeaders['Authorization']!.split(' ').last;

  final client = auth.authenticatedClient(
    http.Client(),
    auth.AccessCredentials(
      auth.AccessToken('Bearer', accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))),
      null,
      ['https://www.googleapis.com/auth/drive.file'],
    ),
  );

  return drive.DriveApi(client);
}
Future<void> logout(BuildContext context) async {
  await googleSignIn.signOut();  // benutze die bereits definierte Instanz

  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed('/'); // oder Login-Seite
  }
}
