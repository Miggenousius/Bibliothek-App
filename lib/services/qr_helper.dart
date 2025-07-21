/*
  Datei: qr_helper.dart
  Zweck: Erzeugen eines QR-Codes als PNG-Bild (Uint8List), um ihn z. B. in Google Drive zu speichern
  Autor: Michi Zumbrunnen
  Letzte Änderung: 14. Juni 2025

  Beschreibung:
  Diese Datei enthält die Funktion `generateQrCodeBytes`, mit der aus einem beliebigen Text (z. B. URL zu einem PDF)
  ein QR-Code erzeugt und als PNG-Bild im Byte-Format (`Uint8List`) zurückgegeben wird.

  Verwendungszweck:
  - Erstellung eines QR-Codes für jedes neu hochgeladene PDF
  - Speicherung des QR-Codes als PNG in einem eigenen Nutzerordner in Google Drive
  - Verknüpfung von physischen Bibliotheksobjekten mit digitalem Inhalt über scannbare QR-Codes

  Technische Hinweise:
  - Verwendet das Paket `qr_flutter`
  - Die Ausgabe ist ein 300x300 PNG-Bild
  - Das Bild kann z. B. mit `uploadQrCodeToDrive(...)` in Google Drive gespeichert werden

  Verwendet in:
  - `upload_to_drive.dart` zur Generierung eines QR-Codes vor dem Speichern in Drive
*/


import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

Future<Uint8List> generateQrCodeBytes(String data) async {
  final qrValidationResult = QrValidator.validate(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
  );

  final qrCode = qrValidationResult.qrCode!;
  final painter = QrPainter.withQr(
    qr: qrCode,
    color: const Color(0xFF000000),
    emptyColor: const Color(0xFFFFFFFF),
    gapless: true,
  );

  final imageData = await painter.toImageData(300);
  return imageData!.buffer.asUint8List();
}
