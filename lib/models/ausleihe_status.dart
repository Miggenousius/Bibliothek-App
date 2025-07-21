/*
  Datei: ausleihe_status.dart
  Zweck: Modellklassen für den aktuellen Ausleihstatus und Reservierungen von PDFs
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Datei enthält zwei Klassen:
  - Reservierung: Einzelne Reservierung mit E-Mail und Datum
  - AusleiheStatus: Ausleihvorgang inkl. Rückgabedatum, Reservierungen und Historie

  Verwendet in:
  - Verwaltung der Ausleihe inkl. Rückgabe und Reservierungsfunktion
  - JSON-Dateien zum Speichern des aktuellen Ausleihstatus pro PDF
*/

class Reservierung {
  final String email;
  final DateTime reserviertAm;

  Reservierung({
    required this.email,
    required this.reserviertAm,
  });

  factory Reservierung.fromJson(Map<String, dynamic> json) => Reservierung(
    email: json['email'],
    reserviertAm: DateTime.parse(json['reserviertAm']),
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'reserviertAm': reserviertAm.toIso8601String(),
  };
}

class AusleiheStatus {
  final String pdfId;
  final String titel;
  String ausgeliehenVon;
  DateTime ausgeliehenAm;
  DateTime rueckgabeBis;
  DateTime? zurueckgegebenAm;
  final List<Reservierung> reservierungen;

  AusleiheStatus({
    required this.pdfId,
    required this.titel,
    required this.ausgeliehenVon,
    required this.ausgeliehenAm,
    required this.rueckgabeBis,
    required this.zurueckgegebenAm,
    required this.reservierungen,
  });

  factory AusleiheStatus.fromJson(Map<String, dynamic> json) => AusleiheStatus(
    pdfId: json['pdfId'],
    titel: json['titel'],
    ausgeliehenVon: json['ausgeliehenVon'],
    ausgeliehenAm: DateTime.parse(json['ausgeliehenAm']),
    rueckgabeBis: DateTime.parse(json['rueckgabeBis']),
    zurueckgegebenAm: json['zurueckgegebenAm'] != null
        ? DateTime.parse(json['zurueckgegebenAm'])
        : null,
    reservierungen: (json['reservierungen'] as List)
        .map((r) => Reservierung.fromJson(r))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'pdfId': pdfId,
    'titel': titel,
    'ausgeliehenVon': ausgeliehenVon,
    'ausgeliehenAm': ausgeliehenAm.toIso8601String(),
    'rueckgabeBis': rueckgabeBis.toIso8601String(),
    'zurueckgegebenAm':
    zurueckgegebenAm?.toIso8601String(),
    'reservierungen': reservierungen.map((r) => r.toJson()).toList(),
  };
}
