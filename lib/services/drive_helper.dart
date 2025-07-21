/*
  Datei: drive_helper.dart
  Zweck: Verwaltung der JSON-Datei und der zugehörigen QR-Codes in Google Drive (Index aller PDF-Einträge)
  Autor: Michi Zumbrunnen
  Letzte Änderung: 14. Juni 2025

  Beschreibung:
  Diese Datei enthält Funktionen zum:
  - Synchronisieren von PDF-Einträgen aus der JSON-Datei in Google Drive nach Hive (`syncFromGoogleDrive`)
  - Erstellen oder Abrufen der zentralen JSON-Datei (`getOrCreateBibliothekJsonInOrdner`)
  - Hinzufügen und Entfernen einzelner PDF-Einträge aus der JSON-Datei
  - Löschen von PDF-Dateien inkl.:
      - PDF auf Google Drive
      - zugehörigem QR-Code im Ordner "QR Codes/[Uploader-Mailadresse]"
      - Eintrag in der lokalen Hive-Datenbank
      - Eintrag in der zentralen JSON-Indexdatei

  Technische Hinweise:
  - Beim Schreiben von JSON-Dateien wird explizit mit Byte-Länge gearbeitet (utf8.encode), um Fehler mit contentLength zu vermeiden.
  - QR-Codes werden anhand des PDF-Titels benannt (Titel.png) und im Nutzerordner abgelegt.

  Verwendet in:
  - Upload-Formular (`bibliothek_formular_erstellen.dart`)
  - Suchseite & Löschfunktion (`suchseite.dart`)
  - Hintergrundsynchronisation beim App-Start
*/



import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import 'package:bibliotheks_app/models/hive_pdf_model.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:flutter/material.dart';

/// Synchronisiert JSON-Datei aus Google Drive nach Hive
Future<void> syncFromGoogleDrive(drive.DriveApi driveApi, String fileId) async {
  try {
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final content = await media.stream.transform(utf8.decoder).join();
    print("📥 Heruntergeladene JSON-Daten: $content");

    if (content.isEmpty) {
      print("⚠️ Die JSON-Datei ist leer oder nicht vorhanden.");
    } else {
      print("📥 JSON-Daten erfolgreich heruntergeladen und verarbeitet.");

      final decoded = json.decode(content) as List<dynamic>;
      final eintraege = decoded.map((e) => PdfEintrag.fromJson(e)).toList();

      final box = await Hive.openBox<PdfEintrag>('pdf_eintraege');
      await box.clear();
      for (final eintrag in eintraege) {
        await box.put(eintrag.id, eintrag);
      }

      print("✅ Synchronisation abgeschlossen (${eintraege.length} Einträge)");
    }
  } catch (e) {
    print("❌ Fehler bei Synchronisation: $e");
  }
}

/// Gibt ID der JSON-Datei zurück oder erstellt sie neu
Future<String> getOrCreateBibliothekJsonInOrdner(drive.DriveApi driveApi) async {
  const ordnerId = '16Bc6D8Yv1ll-zkLsQOp8qxONMe4UvEEd';

  final query =
      "name='bibliothek_index.json' and '$ordnerId' in parents and trashed = false";

  final fileList = await driveApi.files.list(q: query, spaces: 'drive');

  if (fileList.files != null && fileList.files!.isNotEmpty) {
    return fileList.files!.first.id!;
  }

  final mediaStream = Stream.value(utf8.encode("[]"));
  final media = drive.Media(mediaStream, utf8.encode("[]").length);

  final newFile = drive.File()
    ..name = 'bibliothek_index.json'
    ..mimeType = 'application/json'
    ..parents = [ordnerId];

  final created = await driveApi.files.create(newFile, uploadMedia: media);
  return created.id!;
}

/// Fügt einen Eintrag zur JSON-Datei in Google Drive hinzu
Future<void> addPdfEintragToJson(
    drive.DriveApi driveApi,
    String fileId,
    PdfEintrag eintrag,
    ) async {
  try {
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final content = await media.stream.transform(utf8.decoder).join();
    final decoded = json.decode(content) as List<dynamic>;

    decoded.add(eintrag.toJson());

    final updatedJson = json.encode(decoded);
    final encodedJson = utf8.encode(updatedJson);
    final stream = Stream.fromIterable([encodedJson]);
    final mediaUpload = drive.Media(stream, encodedJson.length);

    final updateFile = drive.File();
    await driveApi.files.update(updateFile, fileId, uploadMedia: mediaUpload);

    print("✅ Neuer Eintrag zur JSON-Datei hinzugefügt.");
  } catch (e) {
    print("❌ Fehler beim Aktualisieren der JSON-Datei: $e");
  }
}

/// Löscht einen PDF-Eintrag (Drive-Datei, Hive-Eintrag, JSON)
Future<void> loeschePdfEintrag(PdfEintrag eintrag, BuildContext context) async {
  final user = await GoogleSignIn().signInSilently();
  if (user == null) throw 'Nicht angemeldet';

  final authHeaders = await user.authHeaders;
  final accessToken = authHeaders['Authorization']!.split(' ').last;

  final client = auth.authenticatedClient(
    http.Client(),
    auth.AccessCredentials(
      auth.AccessToken('Bearer', accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))),
      null,
      ['https://www.googleapis.com/auth/drive'],
    ),
  );

  final driveApi = drive.DriveApi(client);

  // Datei-ID aus URL extrahieren
  final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
  final match = regExp.firstMatch(eintrag.pdfUrl);
  if (match == null) throw 'Datei-ID nicht erkannt';
  final fileId = match.group(1)!;

  // Google Drive: Datei löschen
  await driveApi.files.delete(fileId);

  // TXT-Datei löschen (gleicher Titel wie PDF)
  try {
    final txtQuery =
        "name='${eintrag.titel}.txt' and trashed=false";
    final txtResult = await driveApi.files.list(q: txtQuery, spaces: 'drive');

    if (txtResult.files != null && txtResult.files!.isNotEmpty) {
      for (final txtFile in txtResult.files!) {
        await driveApi.files.delete(txtFile.id!);
        print("🗑️ TXT-Datei gelöscht (${txtFile.name})");
      }
    } else {
      print("⚠️ Keine passende TXT-Datei gefunden.");
    }
  } catch (e) {
    print("❌ Fehler beim Löschen der TXT-Datei: $e");
  }

  // QR-Code suchen und löschen
  try {
    const hauptordnerId = '16Bc6D8Yv1ll-zkLsQOp8qxONMe4UvEEd'; // "kigaprima Bibliothek"
    final qrRootId = await getOrCreateFolder('QR Codes', hauptordnerId, driveApi);
    final userFolderId = await getOrCreateFolder(eintrag.uploader, qrRootId, driveApi);

    final query = "name='${eintrag.titel}.png' and '$userFolderId' in parents and trashed = false";
    final result = await driveApi.files.list(q: query, spaces: 'drive');

    if (result.files != null && result.files!.isNotEmpty) {
      final qrFileId = result.files!.first.id!;
      await driveApi.files.delete(qrFileId);
      print("🗑️ QR-Code gelöscht (${eintrag.titel}.png)");
    } else {
      print("⚠️ Kein passender QR-Code gefunden.");
    }
  } catch (e) {
    print("❌ Fehler beim Löschen des QR-Codes: $e");
  }

  // Hive: Eintrag löschen
  final box = await Hive.openBox<PdfEintrag>('pdf_eintraege');
  await box.delete(eintrag.id);

  // JSON-Datei aktualisieren
  final jsonFileId = await getOrCreateBibliothekJsonInOrdner(driveApi);
  await entfernePdfEintragAusJson(driveApi, jsonFileId, eintrag.id);
}
Future<void> entfernePdfEintragAusJson(
    drive.DriveApi driveApi,
    String fileId,
    String eintragId,
    ) async {
  try {
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final content = await media.stream.transform(utf8.decoder).join();
    final decoded = json.decode(content) as List<dynamic>;

    decoded.removeWhere((e) => e['id'] == eintragId);

    final updatedJson = json.encode(decoded);
    final encodedJson = utf8.encode(updatedJson);
    final stream = Stream.fromIterable([encodedJson]);
    final mediaUpload = drive.Media(stream, encodedJson.length);

    final updateFile = drive.File();
    await driveApi.files.update(updateFile, fileId, uploadMedia: mediaUpload);

    print("🗑️ Eintrag aus JSON gelöscht (ID: $eintragId)");
  } catch (e) {
    print("❌ Fehler beim Entfernen aus JSON: $e");
  }
}
/// Erstellt oder gibt die ID eines Ordners in Google Drive zurück
Future<String> getOrCreateFolder(String folderName, String parentId, drive.DriveApi driveApi) async {
  // Prüfen, ob der Ordner bereits existiert
  final query =
      "name='$folderName' and '$parentId' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false";
  final fileList = await driveApi.files.list(q: query, spaces: 'drive');

  if (fileList.files != null && fileList.files!.isNotEmpty) {
    return fileList.files!.first.id!;
  }

  // Ordner erstellen, wenn er nicht existiert
  final folder = drive.File()
    ..name = folderName
    ..mimeType = 'application/vnd.google-apps.folder'
    ..parents = [parentId];

  final createdFolder = await driveApi.files.create(folder);
  return createdFolder.id!;
}
