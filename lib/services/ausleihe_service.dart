/*
  Datei: ausleihe_service.dart
  Zweck: Verwaltung des Ausleihestatus einzelner PDFs über Google Drive (JSON-Dateien)
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Datei enthält Funktionen zum:
  - Laden des aktuellen AusleiheStatus aus einer JSON-Datei in Google Drive
  - Erstellen eines leeren AusleiheStatus, wenn keine Datei vorhanden ist
  - Speichern des Status durch Löschen und erneutes Hochladen der JSON-Datei
  - Dateinamensvergabe und Dateisuche im definierten Ausleihe-Ordner

  Verwendet in:
  - `suchseite.dart` für Ausleihe und Testausleihe
  - `qr_scan_page.dart` für QR-basierte Ausleihe
*/


import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import '../models/ausleihe_status.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../main.dart'; //


const String AUSLEIH_ORDNER_ID = '16fvytAToCE2UztuH60YhY9EZc2mSIcc7';

/// Liefert den Dateinamen für die Ausleihe-Datei eines bestimmten PDFs
String dateinameFuer(String pdfId) => 'ausleihe_$pdfId.json';

/// Sucht nach einer vorhandenen Ausleihe-Datei für ein bestimmtes PDF
Future<String?> findeAusleiheDateiId(String pdfId, drive.DriveApi driveApi) async {
  final fileName = dateinameFuer(pdfId);
  final query = "name='$fileName' and '$AUSLEIH_ORDNER_ID' in parents and trashed=false";

  final result = await driveApi.files.list(q: query, $fields: 'files(id)');
  if (result.files != null && result.files!.isNotEmpty) {
    return result.files!.first.id;
  }
  return null;
}

/// Lädt den AusleiheStatus – oder erstellt einen leeren, wenn keine Datei existiert
Future<AusleiheStatus> ladeOderErstelleAusleiheStatus({
  required String pdfId,
  required String titel,
  required drive.DriveApi driveApi,
}) async {
  final fileId = await findeAusleiheDateiId(pdfId, driveApi);
  if (fileId != null) {
    try {
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (media is drive.Media) {
        final content = await media.stream.transform(utf8.decoder).join();
        return AusleiheStatus.fromJson(jsonDecode(content));
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Laden der Datei: $e');
    }
  }

  // Leeren Status zurückgeben, wenn keine Datei vorhanden ist
  return AusleiheStatus(
    pdfId: pdfId,
    titel: titel,
    ausgeliehenVon: '',
    ausgeliehenAm: DateTime(2000),
    rueckgabeBis: DateTime(2000),
    zurueckgegebenAm: null,
    reservierungen: [],
  );
}

/// Speichert den AusleiheStatus als JSON-Datei in Google Drive
// In speichereAusleiheStatus:
Future<void> speichereAusleiheStatus({
  required AusleiheStatus status,
  required drive.DriveApi driveApi,
  required String verleihEmail,
}) async {
  final pdfId = status.pdfId;
  final fileName = dateinameFuer(pdfId);
  final jsonInhalt = jsonEncode(status.toJson());

  debugPrint('📦 JSON-Inhalt: $jsonInhalt');

  // 1. Alte Datei löschen (wenn vorhanden)
  final alteDateiId = await findeAusleiheDateiId(pdfId, driveApi);
  if (alteDateiId != null) {
    await driveApi.files.delete(alteDateiId);
    debugPrint('🗑️ Alte Ausleihe-Datei gelöscht');
  }
  await syncMitAppsScript(
    status,
    modus: 'ausleihen',
    verleihEmail: verleihEmail,
  );
}

// 🔄 Apps Script Sync außerhalb definieren!
Future<void> syncMitAppsScript(
    AusleiheStatus status, {
      required String modus,
      required String verleihEmail, // 🆕 hinzufügen
    }) async {
  const scriptUrl = 'https://script.google.com/macros/s/AKfycbz0Jw0SKG6QhGbOqUdJwnC9RLP3nELonc6ObOw2IbEW9zQkvRaRLIZ26VrfhaSQ7NkQoA/exec';

  try {
    final body = {
      "modus": modus,
      "ausleihe": {
        "pdfId": status.pdfId,
        "titel": status.titel,
        "ausleihEmail": status.ausgeliehenVon,
        "verleihEmail": verleihEmail, // 🆕 dieses Feld wird ans Apps Script gesendet
        "vorname": status.vorname,
        "nachname": status.nachname,
        "von": status.ausgeliehenAm.toIso8601String(),
        "bis": status.rueckgabeBis.toIso8601String(),
      }
    };

    final response = await http.post(
      Uri.parse(scriptUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      debugPrint('✅ Apps Script erfolgreich:\n${decoded['message']}');
      zeigeSnackbar(decoded['message'] ?? 'Aktion erfolgreich!');
    } else {
      debugPrint('❌ Fehler:\n${response.body}');
      zeigeSnackbar('Fehler: ${decoded['message']}');
    }
  } catch (e) {
    schliesseLadeDialog();
    debugPrint('❌ Ausnahme beim Sync: $e');
    zeigeSnackbar('Verbindungsfehler');
  }
}

void zeigeSnackbar(String nachricht) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nachricht)),
    );
  }
}
void zeigeLadeDialog() {
  final context = navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Bitte warten..."),
            ],
          ),
        );
      },
    );
  }
}

void schliesseLadeDialog() {
  final context = navigatorKey.currentContext;
  if (context != null && Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}


