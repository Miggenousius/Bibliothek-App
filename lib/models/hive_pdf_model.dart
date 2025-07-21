/*
  Datei: hive_pdf_model.dart
  Zweck: Hive-Modellklasse zur Speicherung von PDF-Einträgen in der lokalen Datenbank
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Klasse speichert alle Informationen zu einem PDF-Eintrag wie Titel, Fach,
  Klassenstufe, Zyklus, Uploader und mehr. Sie ist mit Hive annotiert, um
  als persistentes Objekt in der lokalen Datenbank verwendet zu werden.

  Verwendet in:
  - Speicherung und Anzeige der PDF-Einträge
  - JSON-Import/-Export
  - Suche, Ausleihe und Detailansicht
*/

import 'package:hive/hive.dart';

part 'hive_pdf_model.g.dart'; // <- wichtig für die generierte Datei

@HiveType(typeId: 0)
class PdfEintrag extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titel;

  @HiveField(2)
  String fach;

  @HiveField(3)
  String klassenstufe;

  @HiveField(4)
  String zyklus;

  @HiveField(5)
  String stufe;

  @HiveField(6)
  String uploader;

  @HiveField(7)
  String text;

  @HiveField(8)
  DateTime timestamp;

  @HiveField(9)
  String pdfUrl;

  PdfEintrag({
    required this.id,
    required this.titel,
    required this.fach,
    required this.klassenstufe,
    required this.zyklus,
    required this.stufe,
    required this.uploader,
    required this.text,
    required this.timestamp,
    required this.pdfUrl,
  });

  factory PdfEintrag.fromJson(Map<String, dynamic> json) => PdfEintrag(
    id: json['id'],
    titel: json['titel'],
    fach: json['fach'],
    klassenstufe: json['klassenstufe'],
    zyklus: json['zyklus'],
    stufe: json['stufe'],
    uploader: json['uploader'],
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    pdfUrl: json['pdfUrl'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titel': titel,
    'fach': fach,
    'klassenstufe': klassenstufe,
    'zyklus': zyklus,
    'stufe': stufe,
    'uploader': uploader,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'pdfUrl': pdfUrl,
  };
}
