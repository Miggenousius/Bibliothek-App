/*
  Datei: bibliothek_artikel.dart
  Zweck: Modellklasse für einen einzelnen Bibliothekseintrag
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Klasse repräsentiert einen Artikel in der Schulbibliothek.
  Sie enthält alle wichtigen Metadaten wie Titel, Fach, Zyklus, Lagerort,
  Schwierigkeitsgrad und eine optionale Bildreferenz.

  Verwendet in:
  - PDF-Generierung
  - Upload-Formular
  - Anzeige in Such- und Detailansicht
*/

class BibliothekArtikel {
  final String id;
  final String titel;
  final String zyklus;
  final String fach;
  final String klassenstufe;
  final String schwierigkeitsgrad;
  final String verantwortlichePerson;
  final String lagerort;
  final String beinhalteteElemente;
  final String beschreibung;
  final String? fotoPfad;

  BibliothekArtikel({
    required this.id,
    required this.titel,
    required this.zyklus,
    required this.fach,
    required this.klassenstufe,
    required this.schwierigkeitsgrad,
    required this.verantwortlichePerson,
    required this.lagerort,
    required this.beinhalteteElemente,
    required this.beschreibung,
    this.fotoPfad,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titel': titel,
      'zyklus': zyklus,
      'fach': fach,
      'klassenstufe': klassenstufe,
      'schwierigkeitsgrad': schwierigkeitsgrad,
      'verantwortlichePerson': verantwortlichePerson,
      'lagerort': lagerort,
      'beinhalteteElemente': beinhalteteElemente,
      'beschreibung': beschreibung,
      'fotoPfad': fotoPfad,
    };
  }

  factory BibliothekArtikel.fromMap(Map<String, dynamic> map) {
    return BibliothekArtikel(
      id: map['id'],
      titel: map['titel'],
      zyklus: map['zyklus'],
      fach: map['fach'],
      klassenstufe: map['klassenstufe'],
      schwierigkeitsgrad: map['schwierigkeitsgrad'],
      verantwortlichePerson: map['verantwortlichePerson'],
      lagerort: map['lagerort'],
      beinhalteteElemente: map['beinhalteteElemente'],
      beschreibung: map['beschreibung'],
      fotoPfad: map['fotoPfad'],
    );
  }
}
