# 📚 Projektübersicht: Bibliotheks-App

## 🔧 Hauptfunktion

Diese App dient zur Ausleihe, Verwaltung und Recherche von schulischen PDF-Artikeln (z. B. Arbeitsblättern, Unterrichtsmaterialien). Nutzer mit @kigaprima.ch-Adresse können sich via Google anmelden, Materialien hochladen, ausleihen, durchsuchen und verwalten.

---

## 📁 Projektstruktur

### lib/

#### models/
* `hive_pdf_model.dart`: Hive-Modell für PDF-Einträge
* `hive_pdf_model.g.dart`: Generierter TypeAdapter
* `pdf_generator.dart`: Erstellt PDFs
* `ausleihe_status.dart`: Modell für aktuellen Ausleihstatus
* `ausleihe_eintrag.dart`: Einzelausleihe als Datenstruktur

#### pages/
* `startseite/startseite.dart`: Begrüssung & Login
* `bibliothek/bibliotheks_startseite.dart`: Dashboard
* `artikel/bibliothek_formular_erstellen.dart`: PDF-Upload
* `artikel/bibliothek_artikel.dart`: Detailansicht mit Vorschau
* `suche/suchseite.dart`: Suche + Filter + Ausleihe
* `suche/qr_scan_page.dart`: QR-Code-Ausleihe
* `pdf/pdf_webview.dart`: PDF-Vorschau

#### services/
* `upload_to_drive.dart`: Upload & Metadatenhandling
* `drive_helper.dart`: Datei- & JSON-Verwaltung
* `ausleihe_service.dart`: QR-Ausleihe + Statusspeicherung
* `google_auth_helper.dart`: OAuth-Login + Token

#### widgets/
* `google_login.dart`: Login-Button mit Domainfilter

#### main.dart
* Einstiegspunkt, registriert Hive und startet App

---

## ✅ Funktionen (Stand Juni 2025)

* ✅ Google-Login mit Domainfilter
* ✅ PDF-Upload + Metadaten + Drive-Upload + Hive + JSON
* ✅ Suchseite mit Filter & PDF-Vorschau
* ✅ QR-Ausleihe mit automatischer `ausleihe_<id>.json`
* ✅ Nur Eigentümer können löschen
* ✅ Snackbars für Feedback
* 🕓 Erinnerungsfunktion (in Planung)
* 🕓 Favoritenansicht (in Planung)

---

## 🆕 Neu seit 05.06.2025

* QR-Ausleihe in `suchseite.dart`
* Lösch-Feedback über Snackbars
* `onRefresh()`-Callback bei gelöschtem Eintrag
* Fehlervermeidung bei async context-Zugriff
