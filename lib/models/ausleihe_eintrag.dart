/*
  Datei: ausleihe_eintrag.dart
  Zweck: Modellklasse zur Repräsentation eines Ausleihvorgangs eines PDFs
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Klasse enthält Informationen zur Ausleihe eines Bibliotheksartikels.
  Sie bietet Funktionen zum Serialisieren und Deserialisieren (JSON),
  prüft, ob ein Eintrag noch ausgeliehen ist,
  und erlaubt Vergleiche über PDF-ID + Benutzer.

  Verwendet in:
  - JSON-Dateien zur Ausleihverwaltung
  - Funktionen zur Anzeige des aktuellen Ausleihstatus
*/


class AusleiheEintrag {
  final String pdfId;
  final String titel;
  final String ausgeliehenVon;
  final DateTime ausgeliehenAm;
  final DateTime rueckgabeBis;

  AusleiheEintrag({
    required this.pdfId,
    required this.titel,
    required this.ausgeliehenVon,
    required this.ausgeliehenAm,
    required this.rueckgabeBis,
  });

  factory AusleiheEintrag.fromJson(Map<String, dynamic> json) =>
      AusleiheEintrag(
        pdfId: json['pdfId'],
        titel: json['titel'],
        ausgeliehenVon: json['ausgeliehenVon'],
        ausgeliehenAm: DateTime.parse(json['ausgeliehenAm']),
        rueckgabeBis: DateTime.parse(json['rueckgabeBis']),
      );

  Map<String, dynamic> toJson() => {
    'pdfId': pdfId,
    'titel': titel,
    'ausgeliehenVon': ausgeliehenVon,
    'ausgeliehenAm': ausgeliehenAm.toIso8601String(),
    'rueckgabeBis': rueckgabeBis.toIso8601String(),
  };

  @override
  String toString() {
    return 'AusleiheEintrag(pdfId: $pdfId, titel: $titel, ausgeliehenVon: $ausgeliehenVon)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AusleiheEintrag &&
              runtimeType == other.runtimeType &&
              pdfId == other.pdfId &&
              ausgeliehenVon == other.ausgeliehenVon;

  @override
  int get hashCode => pdfId.hashCode ^ ausgeliehenVon.hashCode;

  /// Optional: Gibt true zurück, wenn das PDF aktuell ausgeliehen ist (heute < rueckgabeBis)
  bool istNochAusgeliehen() {
    return DateTime.now().isBefore(rueckgabeBis);
  }
}
