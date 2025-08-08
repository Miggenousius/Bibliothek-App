/*
  Datei: bibliothek_formular_erstellen.dart
  Zweck: Formular zum Erfassen neuer Bibliothekseinträge mit Metadaten, Foto und PDF-Generierung
  Autor: Michi Zumbrunnen
  Letzte Änderung: 14. Juni 2025

  Beschreibung:
  Diese Seite enthält ein Eingabeformular für neue PDFs mit Feldern für Titel, Zyklus,
  Fach, Klassenstufe, Schwierigkeitsgrad, Beschreibung, Lagerort, etc.
  Optional kann ein Foto hinzugefügt werden. Aus den Angaben wird ein PDF generiert und
  in Google Drive hochgeladen. Die Einträge werden lokal in Hive gespeichert.

  Neue Funktionen:
  - Verhindert doppelte Titel (Fehlermeldung bei bereits vergebenem Titel)
  - Validiert den Titel auf unerlaubte Zeichen wie / \ : * ? " < > |
  - "Beinhaltete Elemente" werden automatisch als Bulletpoints formatiert

  Verwendet in:
  - Neuerfassung von Medienartikeln
  - Generierung und Upload von PDFs inkl. QR-Code-Verknüpfung
*/

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/pdf_generator.dart'; //
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'bibliothek_artikel.dart';
import '../../services/upload_to_drive.dart';
import 'package:google_sign_in/google_sign_in.dart'; // falls noch nicht importiert

class BibliothekFormularErstellen extends StatefulWidget {
  const BibliothekFormularErstellen({super.key});

  @override
  _BibliothekFormularErstellenState createState() => _BibliothekFormularErstellenState();
}

class _BibliothekFormularErstellenState extends State<BibliothekFormularErstellen> {
  final _formKey = GlobalKey<FormState>();

  String titel = '';
  String zyklus = '';
  String fach = '';
  String klassenstufe = '';
  String schwierigkeitsgrad = '';
  String verantwortlichePerson = '';
  String lagerort = '';
  String beinhalteteElemente = '';
  String beschreibung = '';
  XFile? foto;

  final List<String> zyklusOptionen = ['1. Zyklus', '2. Zyklus', '3. Zyklus'];
  final List<String> schwierigkeitsOptionen = ['leicht', 'mittel', 'schwierig', 'variabel'];
  final List<String> fachOptionen = [
    'Mathematik', 'Deutsch', 'Englisch', 'Französisch', 'Sport',
    'Kunst', 'Werken', 'Handarbeit', 'Sachunterricht',
    'Musik', 'Medien und Informatik', 'Sonstiges'
  ];
  final List<String> klassenstufenOptionen = [
    '1. Kindergarten', '2. Kindergarten',
    '1. Klasse', '2. Klasse', '3. Klasse',
    '4. Klasse', '5. Klasse', '6. Klasse'
  ];

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        foto = pickedFile;
      });
    }
  }

  final TextEditingController _elementeController = TextEditingController();
  String bulletPreview = '';

  @override
  void initState() {
    super.initState();
    _elementeController.addListener(() {
      final lines = _elementeController.text.split('\n').where((line) => line.trim().isNotEmpty);
      setState(() {
        bulletPreview = lines.map((line) => '• ${line.trim()}').join('\n');
      });
    });
  }

  void submitForm() async {
    final localContext = context;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final box = Hive.box('bibliothek_artikel');
      beinhalteteElemente = _elementeController.text;

      final artikel = BibliothekArtikel(
        id: const Uuid().v4(),
        titel: titel,
        zyklus: zyklus,
        fach: fach,
        klassenstufe: klassenstufe,
        schwierigkeitsgrad: schwierigkeitsgrad,
        verantwortlichePerson: verantwortlichePerson,
        lagerort: lagerort,
        beinhalteteElemente: beinhalteteElemente,
        beschreibung: beschreibung,
        fotoPfad: foto?.path,
      );

      await box.put(artikel.id, artikel.toMap());

      final pdfFile = await generatePdf(artikel);
      final googleSignIn = GoogleSignIn(
        clientId: '863090442961-f4j6avtfiem6d7fe8op4s6emaof1f3pi.apps.googleusercontent.com',
        scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
      );

      final googleUser = await GoogleSignIn().signInSilently();

      if (googleUser != null) {
        await uploadPdfToDrive(
          pdfFile,
          googleUser,
          localContext,
          artikel.fach,
          artikel.klassenstufe,
          artikel.titel,
          artikel.zyklus,
          artikel.schwierigkeitsgrad,
          artikel.lagerort,
          artikel.beinhalteteElemente,
          artikel.beschreibung,
          '', // pdfTextContent kann später ersetzt werden
        );

        if (mounted) {
          Navigator.pop(localContext);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            const SnackBar(content: Text('Fehler: Kein eingeloggter Benutzer')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuer Bibliotheksartikel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Titel'),
                onSaved: (value) => titel = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Titel angeben';
                  }
                  final verboteneZeichen = RegExp(r'[\/:*?"<>|]');
                  if (verboteneZeichen.hasMatch(value)) {
                    return 'Der Titel darf keine Sonderzeichen wie / \\ : * ? " < > | enthalten.';
                  }
                  final box = Hive.box('bibliothek_artikel');
                  final vorhandeneTitel = box.values
                      .cast<Map>()
                      .map((e) => e['titel']?.toString().toLowerCase())
                      .whereType<String>()
                      .toList();
                  if (vorhandeneTitel.contains(value.toLowerCase())) {
                    return 'Ein Artikel mit diesem Titel existiert bereits.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Zyklus'),
                items: zyklusOptionen.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                onChanged: (value) => zyklus = value as String,
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Fach'),
                items: fachOptionen.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (value) => setState(() => fach = value as String),
                validator: (value) => value == null || value.isEmpty ? 'Bitte Fach auswählen' : null,
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Klassenstufe'),
                items: klassenstufenOptionen.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (value) => setState(() => klassenstufe = value as String),
                validator: (value) => value == null || value.isEmpty ? 'Bitte Klassenstufe auswählen' : null,
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Schwierigkeitsgrad'),
                items: schwierigkeitsOptionen.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (value) => schwierigkeitsgrad = value as String,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Verantwortliche Person'),
                onSaved: (value) => verantwortlichePerson = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Lagerort'),
                onSaved: (value) => lagerort = value ?? '',
              ),
              TextFormField(
                controller: _elementeController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Beinhaltete Elemente',
                  hintText: 'z.\u202Fz.\u202F\n• Leseblatt\n• Fragen zum Text\n• Wortschatzübung',
                  border: UnderlineInputBorder(),
                ),
                onChanged: (text) {
                  final lines = text.split('\n');
                  for (int i = 0; i < lines.length; i++) {
                    if (lines[i].isNotEmpty && !lines[i].trimLeft().startsWith('•')) {
                      lines[i] = '• ${lines[i].trimLeft()}';
                    }
                  }
                  final newText = lines.join('\n');
                  if (newText != text) {
                    _elementeController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Beschreibung / Hinweise zur Nutzung'),
                maxLines: 3,
                onSaved: (value) => beschreibung = value ?? '',
              ),
              const SizedBox(height: 16),
              foto != null
                  ? Image.file(
                File(foto!.path),
                height: 150,
              )
                  : const Text('Kein Foto ausgewählt'),
              TextButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Foto auswählen'),
                onPressed: () => zeigeBildQuelleAuswahl(context),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: submitForm,
                child: const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void zeigeBildQuelleAuswahl(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
