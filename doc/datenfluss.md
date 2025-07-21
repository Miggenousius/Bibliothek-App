# 🔄 Datenfluss der Bibliotheks-App

## 1. App-Start

* `main.dart`: Hive-Initialisierung
* Login via `startseite.dart` → `google_login.dart`
* Nach Login: `bibliotheks_startseite.dart`
* Drive-Sync: JSON laden & Hive befüllen

## 2. PDF-Erstellung

* Seite: `bibliothek_formular_erstellen.dart`
* Nach Speichern:
  - PDF generieren
  - Drive-Upload in Unterordner
  - JSON & Hive aktualisieren

## 3. Suche

* `suchseite.dart`: Text- und Filter-Suche in Hive
* Anzeige als `PdfVorschauCard`
* Detailansicht über `bibliothek_artikel.dart`

## 4. Ausleihe

* Button (Icon) auf `suchseite.dart`
* Startet `qr_scan_page.dart`
* Scan verarbeitet → JSON-Ausleihe wird erstellt

## 5. Löschen

* Nur Uploader: `eintrag.uploader == currentUserEmail`
* Datei in Drive löschen
* JSON & Hive entfernen via `drive_helper.dart`

---

## 🔁 Übersicht

