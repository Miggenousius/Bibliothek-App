/*
  Datei: pdf_generator.dart
  Zweck: Erstellt ein PDF-Dokument aus den Metadaten eines Bibliothek-Artikels
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Datei enthält die Funktion `generatePdf(...)`, die ein strukturiertes PDF
  mit Titel, Fach, Zyklus, Bild, Beschreibung und weiteren Metadaten erstellt.
  Falls ein Foto vorhanden ist, wird es eingebunden. Das PDF wird lokal gespeichert.

  Verwendet in:
  - Detailansicht und Druckfunktionen von Bibliothekseinträgen
  - QR-Code-Erstellung für ausdruckbare Medien
*/


import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../pages/artikel/bibliothek_artikel.dart';
import 'package:flutter/services.dart' show rootBundle;


Future<File> generatePdf(BibliothekArtikel artikel) async {
  final pdf = pw.Document();

  // Roboto laden
  final robotoFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto/static/Roboto-Regular.ttf'),
  );

  // Lade Bild (falls vorhanden)
  pw.Widget? fotoWidget;
  if (artikel.fotoPfad != null && File(artikel.fotoPfad!).existsSync()) {
    final image = pw.MemoryImage(File(artikel.fotoPfad!).readAsBytesSync());
    fotoWidget = pw.Image(image, height: 150);
  }

  final textStyle = pw.TextStyle(font: robotoFont);

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('KigaPrima-Perlen', style: pw.TextStyle(fontSize: 24, font: robotoFont)),
          pw.SizedBox(height: 16),
          if (fotoWidget != null) fotoWidget,
          pw.SizedBox(height: 16),
          pw.Text('Titel: ${artikel.titel}', style: textStyle),
          pw.Text('Zyklus: ${artikel.zyklus}', style: textStyle),
          pw.Text('Fach: ${artikel.fach}', style: textStyle),
          pw.Text('Klassenstufe: ${artikel.klassenstufe}', style: textStyle),
          pw.Text('Schwierigkeitsgrad: ${artikel.schwierigkeitsgrad}', style: textStyle),
          pw.Text('Verantwortliche Person: ${artikel.verantwortlichePerson}', style: textStyle),
          pw.Text('Lagerort: ${artikel.lagerort}', style: textStyle),
          pw.SizedBox(height: 8),
          pw.Text('Beinhaltete Elemente:', style: textStyle),
          pw.Text(artikel.beinhalteteElemente, style: textStyle),
          pw.SizedBox(height: 8),
          pw.Text('Hinweise zur Nutzung:', style: textStyle),
          pw.Text(artikel.beschreibung, style: textStyle),
        ],
      ),
    ),
  );

  final output = await getApplicationDocumentsDirectory();
  final file = File('${output.path}/${artikel.id}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}

