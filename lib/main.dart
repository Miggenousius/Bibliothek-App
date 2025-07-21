/*
  Datei: main.dart
  Zweck: Einstiegspunkt der Bibliotheks-App und Initialisierung von Hive
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Datei initialisiert:
  - das Flutter-Framework und Hive (lokale Datenbank)
  - die Registrierung und Öffnung aller relevanten Hive-Boxen
    (PDF-Einträge, Favoriten, Artikel)
  - den Start der App über `LibraryApp`, welche zur `Startseite` führt

  Verwendet in:
  - App-Startprozess
  - Setup und Verfügbarmachung aller lokalen Datenquellen
*/


import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/startseite/startseite.dart';
import 'package:bibliotheks_app/models/hive_pdf_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(PdfEintragAdapter());
  await Hive.openBox('bibliothek_artikel');
  await Hive.openBox<PdfEintrag>('pdf_eintraege');
  await Hive.openBox<String>('favoriten');

  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schulbibliothek',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: Startseite(),
    );
  }
}
