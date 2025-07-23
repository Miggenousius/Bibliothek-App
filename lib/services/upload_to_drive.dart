/*
  Datei: upload_to_drive.dart
  Zweck: Hochladen von PDF-Dateien nach Google Drive mit Ordnerstruktur, Rechtevergabe, QR-Code-Erzeugung und Index-Aktualisierung
  Autor: Michi Zumbrunnen
  Letzte Änderung: 14. Juni 2025

  Beschreibung:
  Diese Datei enthält die Logik zum:
  - Erstellen der Ordnerstruktur in Google Drive (Fach → Klassenstufe)
  - Hochladen des PDF-Dokuments inkl. Freigabe als öffentlich lesbar
  - Erzeugen eines QR-Codes, der direkt auf das PDF verweist
  - Hochladen des QR-Codes in den persönlichen Unterordner im Ordner "QR Codes"
  - Erstellen und Speichern eines `PdfEintrag`-Objekts (lokal in Hive und zentral in JSON-Datei)
  - Aktualisieren der zentralen JSON-Datei zur Such- und Verwaltungsstruktur

  Struktur der Ablage in Google Drive:
  - PDFs: Hauptordner → Fach → Klassenstufe → PDF-Datei
  - QR-Codes: Root-Ordner "QR Codes" → Unterordner pro Nutzer (E-Mail-Adresse) → PNG-Dateien mit PDF-Titel als Name

  Verwendet in:
  - `bibliothek_formular_erstellen.dart` zur Speicherung eines neuen Artikels
  - Datei- und Metadatenverwaltung in Google Drive
  - QR-Code-Verwaltung zur eindeutigen Identifikation von physischen Ausleihobjekten
*/

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bibliotheks_app/models/hive_pdf_model.dart';
import 'package:bibliotheks_app/services/drive_helper.dart';
import 'package:hive/hive.dart';
import 'package:bibliotheks_app/services/qr_helper.dart';

Future<void> uploadPdfToDrive(
    File pdfFile,
    GoogleSignInAccount user,
    BuildContext context,
    String fach,
    String klassenstufe,
    String titel,
    String zyklus,
    String schwierigkeitsgrad,
    String lagerort,
    String beinhalteteElemente,
    String hinweiseZurNutzung,
    String pdfTextContent,
    ) async {

  try {
    // Ladeanzeige
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Authentifizierung
    final authHeaders = await user.authHeaders;
    final accessToken = authHeaders['Authorization']!.split(' ').last;

    final client = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        ['https://www.googleapis.com/auth/drive.file'],
      ),
    );

    final driveApi = drive.DriveApi(client);
    const String hauptordnerId = '16Bc6D8Yv1ll-zkLsQOp8qxONMe4UvEEd';

    // Ordnerstruktur erstellen
    final fachOrdnerId = await getOrCreateFolder(fach, hauptordnerId, driveApi);
    final klasseOrdnerId = await getOrCreateFolder(klassenstufe, fachOrdnerId, driveApi);

    // Zyklus berechnen
    final zyklus = klassenstufe.contains('1.') || klassenstufe.contains('2.')
        ? '1. Zyklus'
        : klassenstufe.contains('3.') || klassenstufe.contains('4.')
        ? '2. Zyklus'
        : klassenstufe.contains('5.') || klassenstufe.contains('6.')
        ? '3. Zyklus'
        : 'Unbekannter Zyklus';

    // PDF hochladen
    final fileMetadata = drive.File()
      ..name = '$titel.pdf'
      ..parents = [klasseOrdnerId];

    final media = drive.Media(pdfFile.openRead(), await pdfFile.length());
    final uploadedFile = await driveApi.files.create(fileMetadata, uploadMedia: media);

    // TXT-Datei erzeugen & hochladen
    final txtInhalt = '''
Titel: $titel
Zyklus: $zyklus
Fach: $fach
Klassenstufe: $klassenstufe
Schwierigkeitsgrad: $schwierigkeitsgrad
Verantwortliche Person: ${user.displayName ?? user.email}
Lagerort: $lagerort
Beinhaltete Elemente:
$beinhalteteElemente
Hinweise zur Nutzung:
$hinweiseZurNutzung
''';

    final txtBytes = utf8.encode(txtInhalt);
    final txtFileName = '$titel.txt';
    final txtMedia = drive.Media(Stream.value(txtBytes), txtBytes.length);

    final txtFileMetadata = drive.File()
      ..name = txtFileName
      ..parents = [klasseOrdnerId]
      ..mimeType = 'text/plain';

    await driveApi.files.create(txtFileMetadata, uploadMedia: txtMedia);

    // PDF öffentlich freigeben
    await driveApi.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      uploadedFile.id!,
    );

    final fileId = uploadedFile.id;
    final pdfUrl = 'https://drive.google.com/file/d/$fileId/view?usp=sharing';

    // QR-Code generieren & hochladen
    final qrImageBytes = await generateQrCodeBytes(pdfUrl);
    await uploadQrCodeToDrive(
      qrImageBytes: qrImageBytes,
      fileName: titel,
      userEmail: user.email,
      driveApi: driveApi,
    );

    print('Uploader-E-Mail beim Hochladen: ${user.email}');

    // PdfEintrag erstellen
    final kompletterText = '''
Titel: $titel
Fach: $fach
Klassenstufe: $klassenstufe
Zyklus: $zyklus
Schwierigkeitsgrad: mittel

$pdfTextContent
''';

    final eintrag = PdfEintrag(
      id: fileId!,  // 🔁 Das ist die echte Drive-ID!
      titel: titel,
      fach: fach,
      klassenstufe: klassenstufe,
      zyklus: zyklus,
      stufe: 'mittel',
      uploader: user.email,
      text: kompletterText,
      timestamp: DateTime.now().toUtc(),
      pdfUrl: pdfUrl,
    );

    // JSON-Datei aktualisieren
    final jsonFileId = await getOrCreateBibliothekJsonInOrdner(driveApi);
    await addPdfEintragToJson(driveApi, jsonFileId, eintrag);

    // In Hive speichern
    final box = await Hive.openBox<PdfEintrag>('pdf_eintraege');
    await box.put(eintrag.id, eintrag);

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF erfolgreich hochgeladen!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hochladen: $e')),
      );
    }
  }
}

Future<String> getOrCreateFolder(
    String name,
    String parentId,
    drive.DriveApi driveApi,
    ) async {
  final folderQuery =
      "mimeType='application/vnd.google-apps.folder' and name='$name' and '$parentId' in parents and trashed = false";

  final folders = await driveApi.files.list(
    q: folderQuery,
    $fields: "files(id, name)",
  );

  if (folders.files != null && folders.files!.isNotEmpty) {
    return folders.files!.first.id!;
  } else {
    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [parentId];

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }
}

Future<void> uploadQrCodeToDrive({
  required Uint8List qrImageBytes,
  required String fileName,
  required String userEmail,
  required drive.DriveApi driveApi,
}) async {
  const String hauptordnerId = '16Bc6D8Yv1ll-zkLsQOp8qxONMe4UvEEd';
  final qrRootId = await getOrCreateFolder('QR Codes', hauptordnerId, driveApi);
  final userFolderId = await getOrCreateFolder(userEmail, qrRootId, driveApi);

  final media = drive.Media(Stream.fromIterable([qrImageBytes]), qrImageBytes.length);
  final file = drive.File()
    ..name = '$fileName.png'
    ..mimeType = 'image/png'
    ..parents = [userFolderId];

  await driveApi.files.create(file, uploadMedia: media);
}
