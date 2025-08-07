/*
  Datei: suchseite.dart
  Zweck: Durchsuchen und Filtern von Bibliothekseinträgen mit Detailansicht, Ausleihe und QR-Scan
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Seite ermöglicht die Suche nach PDF-Einträgen anhand von Stichworten und Filtern
  (Zyklus, Fach, Klassenstufe, Schwierigkeitsgrad). Sie zeigt eine Vorschau mit Detailzugriff,
  erlaubt das Löschen eigener Einträge und ermöglicht das Ausleihen physischer Objekte über QR-Code.
  Die Ausleihdaten werden mit dem aktuell angemeldeten Nutzer in Google Drive gespeichert.

  Verwendet in:
  - Navigation ab Startseite
  - QR-Code-Ausleihe (via `qr_scan_page.dart`)
  - Anzeige & Verwaltung von PDF-Materialien
  - Lokale Hive-Datenbank & Google-Drive-Anbindung
*/


import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/hive_pdf_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bibliotheks_app/services/drive_helper.dart';
import 'package:bibliotheks_app/pages/artikel/bibliothek_artikel_page.dart';
import 'package:bibliotheks_app/pages/ausleihe/qr_scan_page.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:bibliotheks_app/services/google_auth_helper.dart';
import 'package:url_launcher/url_launcher.dart';



class Suchseite extends StatefulWidget {
  const Suchseite({super.key});

  @override
  State<Suchseite> createState() => _SuchseiteState();
}

class _SuchseiteState extends State<Suchseite> {
  final TextEditingController suchbegriffController = TextEditingController();

  GoogleSignInAccount? aktuellerUser;

  String suchbegriff = '';
  String dropdownZyklus = '';
  String dropdownFach = '';
  String dropdownKlasse = '';
  String dropdownSchwierigkeit = '';

  String ausgewaehlterZyklus = '';
  String ausgewaehltesFach = '';
  String ausgewaehlteKlasse = '';
  String ausgewaehlteSchwierigkeit = '';


  final List<String> zyklen = ['1. Zyklus', '2. Zyklus', '3. Zyklus'];
  final List<String> faecher = ['Mathematik', 'Deutsch', 'Englisch', 'Französisch', 'Sport', 'Kunst', 'Werken', 'Handarbeit', 'Sachunterricht', 'Musik', 'Medien und Informatik', 'Sonstiges'];
  final List<String> klassenstufen = ['1. Klasse', '2. Klasse', '3. Klasse'];
  final List<String> schwierigkeiten = ['leicht', 'mittel', 'schwierig'];

  late List<PdfEintrag> alleEintraege;

  @override
  void initState() {
    super.initState();
    ladeEintraegeNeuUndAktualisiere();

    GoogleSignIn().signInSilently().then((user) {
      setState(() {
        aktuellerUser = user;
      });
    });
  }


  void ladeEintraegeNeuUndAktualisiere() {
    setState(() {
      alleEintraege = Hive.box<PdfEintrag>('pdf_eintraege').values.toList();
    });
  }

  Future<void> aktualisiereEintraegeVomDrive() async {
    try {
      var user = await GoogleSignIn().signInSilently();
      if (user == null) user = await GoogleSignIn().signIn();
      if (user == null) return;

      final result = await googleDriveApiHolen(); // ⬅️ Neues Rückgabeobjekt
      final driveApi = result.driveApi;

      // 1. Daten aus Drive laden und in Hive speichern
      await syncFromGoogleDrive(driveApi, '1qIXPUq2xsbrQzkrQ01-iCjT_hWArkpBh');

      // 2. Hive-Inhalte neu laden
      setState(() {
        alleEintraege = Hive.box<PdfEintrag>('pdf_eintraege').values.toList();
      });
    } catch (e) {
      print("❌ Fehler beim Aktualisieren: $e");
    }
  }



  void sucheStarten() {
    setState(() {
      suchbegriff = suchbegriffController.text.toLowerCase();
      ausgewaehlterZyklus = dropdownZyklus;
      ausgewaehltesFach = dropdownFach;
      ausgewaehlteKlasse = dropdownKlasse;
      ausgewaehlteSchwierigkeit = dropdownSchwierigkeit;
    });
  }
  void filterZuruecksetzen() {
    setState(() {
      suchbegriffController.clear();
      suchbegriff = '';
      dropdownZyklus = '';
      dropdownFach = '';
      dropdownKlasse = '';
      dropdownSchwierigkeit = '';
      ausgewaehlterZyklus = '';
      ausgewaehltesFach = '';
      ausgewaehlteKlasse = '';
      ausgewaehlteSchwierigkeit = '';
    });
  }

  @override
  Widget build(BuildContext context) {

    final suchbegriffKlein = suchbegriff.toLowerCase();

    final passendeEintraege = alleEintraege.where((eintrag) {
      final titel = eintrag.titel.toLowerCase();
      final text = eintrag.text.toLowerCase();

      return (titel.contains(suchbegriffKlein) || text.contains(suchbegriffKlein)) &&
          (ausgewaehlterZyklus.isEmpty || eintrag.zyklus == ausgewaehlterZyklus) &&
          (ausgewaehltesFach.isEmpty || eintrag.fach == ausgewaehltesFach) &&
          (ausgewaehlteKlasse.isEmpty || eintrag.klassenstufe == ausgewaehlteKlasse) &&
          (ausgewaehlteSchwierigkeit.isEmpty || eintrag.stufe == ausgewaehlteSchwierigkeit);
    }).toList();

    ('Filter: Zyklus=$ausgewaehlterZyklus, Fach=$ausgewaehltesFach, Klasse=$ausgewaehlteKlasse, Schwierigkeit=$ausgewaehlteSchwierigkeit, Suchbegriff=$suchbegriff');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliotheksartikel suchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Daten aktualisieren',
            onPressed: () async {
              await aktualisiereEintraegeVomDrive();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //  Hier ist das einklappbares Filtermenü
            // Immer sichtbares Suchfeld
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: suchbegriffController,
                    decoration: const InputDecoration(
                      labelText: 'Suchbegriff',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: sucheStarten,
                  tooltip: 'Suche starten',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ExpansionTile(
              initiallyExpanded: false,
              title: const Text('Filter anzeigen'),
              children: [
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: dropdownZyklus,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Alle')),
                    ...zyklen.map((zyklus) =>
                        DropdownMenuItem(value: zyklus, child: Text(zyklus))),
                  ],
                  onChanged: (value) =>
                      setState(() => dropdownZyklus = value ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Zyklus (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: dropdownFach,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Alle')),
                    ...faecher.map((fach) =>
                        DropdownMenuItem(value: fach, child: Text(fach))),
                  ],
                  onChanged: (value) =>
                      setState(() => dropdownFach = value ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Fach (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: dropdownKlasse,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Alle')),
                    ...klassenstufen.map((klasse) =>
                        DropdownMenuItem(value: klasse, child: Text(klasse))),
                  ],
                  onChanged: (value) =>
                      setState(() => dropdownKlasse = value ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Klassenstufe (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: dropdownSchwierigkeit,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Alle')),
                    ...schwierigkeiten.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (value) =>
                      setState(() => dropdownSchwierigkeit = value ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Schwierigkeit (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: sucheStarten,
                  icon: const Icon(Icons.search),
                  label: const Text('Suche starten'),
                ),
                TextButton.icon(
                  onPressed: filterZuruecksetzen,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Filter zurücksetzen'),
                ),
                const SizedBox(height: 10),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  if (passendeEintraege.isNotEmpty)
                    ...passendeEintraege.map((e) => PdfVorschauCard(e, aktuellerUser?.email ?? '', onRefresh: ladeEintraegeNeuUndAktualisiere)),
                  if (passendeEintraege.isEmpty)
                    const Text('Keine Ergebnisse gefunden.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              ],
            )
          ],
        ),
      ),
    );
  }
}

class PdfVorschauCard extends StatelessWidget {
  final PdfEintrag eintrag;
  final String currentUserEmail;
  final VoidCallback onRefresh;

  const PdfVorschauCard(this.eintrag, this.currentUserEmail, {required this.onRefresh, super.key});

  @override
  Widget build(BuildContext context) {
    final bool istUploader = eintrag.uploader.trim().toLowerCase() == currentUserEmail.trim().toLowerCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eintrag.titel, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Zyklus: ${eintrag.zyklus}, Stufe: ${eintrag.stufe}"),
            Text("Uploader: ${eintrag.uploader}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.green),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BibliothekArtikelPage(eintrag: eintrag),
                      ),
                    );
                  },
                ),
//                IconButton(
//                  icon: Icon(Icons.qr_code_scanner, color: Colors.blue),
//                  onPressed: () {
//                    Navigator.push(
//                      context,
//                      MaterialPageRoute(
//                        builder: (_) => QRScanPage(
//                          pdfId: eintrag.id,
//                          titel: eintrag.titel,
//                          verleihEmail: eintrag.uploader,
//                        ),
//                      ),
//                    );
//                  },
//                ),
//                if (istUploader)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _bestaetigeUndLoesche(context),
                  ),
                IconButton(
                  icon: Icon(Icons.email, color: Colors.black),
                  onPressed: () async {
                    final email = eintrag.uploader;
                    final uri = Uri(
                      scheme: 'mailto',
                      path: email,
                      query: Uri.encodeFull('subject=Frage zum Bibliotheksartikel "${eintrag.titel}"'),
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-Mail-App konnte nicht geöffnet werden.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bestaetigeUndLoesche(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF löschen'),
        content: const Text('Willst du dieses PDF wirklich löschen?'),
        actions: [
          TextButton(
            child: const Text('Abbrechen'),
            onPressed: () => navigator.pop(false),
          ),
          ElevatedButton(
            child: const Text('Löschen'),
            onPressed: () => navigator.pop(true),
          ),
        ],
      ),
    );

    if (bestaetigt != true) return;

    try {
      await loeschePdfEintrag(eintrag, context); // context nur, wenn wirklich nötig
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('PDF gelöscht.')),
      );
      onRefresh();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen: $e')),
      );
    }
  }
}