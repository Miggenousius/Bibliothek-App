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
  String pdfId;
  String titel;
  String ausgeliehenVon;
  String? vorname;
  String? nachname;
  DateTime ausgeliehenAm;
  DateTime rueckgabeBis;
  DateTime? zurueckgegebenAm;
  List<String> reservierungen;

  AusleiheStatus({
    required this.pdfId,
    required this.titel,
    required this.ausgeliehenVon,
    this.vorname,
    this.nachname,
    required this.ausgeliehenAm,
    required this.rueckgabeBis,
    required this.zurueckgegebenAm,
    required this.reservierungen,
  });

  factory AusleiheStatus.fromJson(Map<String, dynamic> json) {
    return AusleiheStatus(
      pdfId: json['pdfId'],
      titel: json['titel'],
      ausgeliehenVon: json['ausgeliehenVon'],
      vorname: json['vorname'],
      nachname: json['nachname'],
      ausgeliehenAm: DateTime.parse(json['ausgeliehenAm']),
      rueckgabeBis: DateTime.parse(json['rueckgabeBis']),
      zurueckgegebenAm: json['zurueckgegebenAm'] != null
          ? DateTime.parse(json['zurueckgegebenAm'])
          : null,
      reservierungen: List<String>.from(json['reservierungen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdfId': pdfId,
      'titel': titel,
      'ausgeliehenVon': ausgeliehenVon,
      'vorname': vorname,
      'nachname': nachname,
      'ausgeliehenAm': ausgeliehenAm.toIso8601String(),
      'rueckgabeBis': rueckgabeBis.toIso8601String(),
      'zurueckgegebenAm': zurueckgegebenAm?.toIso8601String(),
      'reservierungen': reservierungen,
    };
  }
}
