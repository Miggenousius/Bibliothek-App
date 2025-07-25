import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:bibliotheks_app/services/ausleihe_service.dart';
import 'package:bibliotheks_app/services/google_auth_helper.dart';

class Ausleihformular extends StatefulWidget {
  final String pdfId;
  final String titel;

  const Ausleihformular({super.key, required this.pdfId, required this.titel});

  @override
  State<Ausleihformular> createState() => _AusleihformularState();
}

class _AusleihformularState extends State<Ausleihformular> {
  final _formKey = GlobalKey<FormState>();

  final _vornameController = TextEditingController();
  final _nachnameController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _vonDatum;
  DateTime? _bisDatum;

  @override
  void initState() {
    super.initState();
    _initialisiereBenutzerdaten();
  }
  void _zeigeLadeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initialisiereBenutzerdaten() async {
    final user = await GoogleSignIn().signInSilently();
    final email = user?.email ?? '';

    final teile = email.split('@').first.split('.');
    final vorname = teile.isNotEmpty ? teile[0] : '';
    final nachname = teile.length > 1 ? teile[1] : '';

    setState(() {
      _vornameController.text = vorname.isNotEmpty
          ? vorname[0].toUpperCase() + vorname.substring(1)
          : '';
      _nachnameController.text = nachname.isNotEmpty
          ? nachname[0].toUpperCase() + nachname.substring(1)
          : '';
      _emailController.text = email;
    });
  }

  Future<void> _waehleDatum({required bool istVon}) async {
    final initialDate = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        if (istVon) {
          _vonDatum = selected;
        } else {
          _bisDatum = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Ausleihe erfassen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Artikel: ${widget.titel}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _vornameController,
                decoration: const InputDecoration(labelText: 'Vorname'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Vorname eingeben';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nachnameController,
                decoration: const InputDecoration(labelText: 'Nachname'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Nachname eingeben';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-Mail'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte E-Mail eingeben';
                  }
                  if (!value.contains('@')) {
                    return 'Ungültige E-Mail-Adresse';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(_vonDatum == null
                        ? 'Von: nicht gewählt'
                        : 'Von: ${dateFormat.format(_vonDatum!)}'),
                  ),
                  ElevatedButton(
                    onPressed: () => _waehleDatum(istVon: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vonDatum != null ? Colors.grey.shade400 : null,
                    ),
                    child: Text(_vonDatum != null ? 'Erneut wählen' : 'Datum wählen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(_bisDatum == null
                        ? 'Bis: nicht gewählt'
                        : 'Bis: ${dateFormat.format(_bisDatum!)}'),
                  ),
                  ElevatedButton(
                    onPressed: () => _waehleDatum(istVon: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bisDatum != null ? Colors.grey.shade400 : null,
                    ),
                    child: Text(_bisDatum != null ? 'Erneut wählen' : 'Datum wählen'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Ausleihe speichern'),
                onPressed: () async {
                  final isValid = _formKey.currentState!.validate();
                  if (!isValid || _vonDatum == null || _bisDatum == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Bitte alle Felder und Daten korrekt ausfüllen'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  _zeigeLadeDialog(); // 🔄 Ladeindikator direkt beim Klick

                  try {
                    final result = await googleDriveApiHolen();
                    final driveApi = result.driveApi;

                    final status = await ladeOderErstelleAusleiheStatus(
                      pdfId: widget.pdfId,
                      titel: widget.titel,
                      driveApi: driveApi,
                    );

                    status.ausgeliehenVon = _emailController.text.trim();
                    status.vorname = _vornameController.text.trim();
                    status.nachname = _nachnameController.text.trim();
                    status.ausgeliehenAm = _vonDatum!;
                    status.rueckgabeBis = _bisDatum!;
                    status.zurueckgegebenAm = null;

                    await speichereAusleiheStatus(status: status, driveApi: driveApi);

                    if (mounted) {
                      Navigator.of(context).pop(); // 🔚 Ladeindikator schließen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Bibliotheksartikel erfolgreich ausgeliehen'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context); // zurück zur vorherigen Seite
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(); // 🔚 Ladeindikator schließen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Fehler beim Ausleihen: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
