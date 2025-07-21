# ☁️ Google Drive Integration – Überblick

## 🔐 Authentifizierung

* Login via `google_sign_in`, gefiltert auf `@kigaprima.ch`
* Initialisierung in `google_auth_helper.dart`

## 📁 Ordnerstruktur

* Hauptordner-ID: `16Bc6D8Yv1ll-zkLsQOp8qxONMe4UvEEd`
* Unterordner: nach `Fach/Klassenstufe`
* Automatische Ordnererstellung bei Upload

## 📄 JSON-Dateien

### `bibliothek_index.json`
* Beinhaltet Metadaten aller PDFs (`PdfEintrag`)
* Aktualisiert nach Upload & bei Login (sync)

### `ausleihe_<id>.json`
* Enthält aktuellen Ausleihstatus und Reservierungen
* Erstellt beim ersten Ausleihvorgang per QR

## 📤 Upload-Prozess

1. Formular ausfüllen (`bibliothek_formular_erstellen.dart`)
2. PDF generieren (`pdf_generator.dart`)
3. Upload zu Drive → Link abrufen
4. Metadaten in JSON & Hive speichern

## 🗑 Löschen

* Nur für Uploader
* Datei-ID aus URL extrahieren
* PDF + JSON-Eintrag + Hive-Eintrag löschen

## 🔄 Synchronisation

* Automatisch bei Login über `syncFromGoogleDrive`
* Frische JSON-Daten werden lokal gespeichert
