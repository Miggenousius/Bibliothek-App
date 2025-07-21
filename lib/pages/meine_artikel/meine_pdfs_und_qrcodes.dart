import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/hive_pdf_model.dart';
import '../artikel/bibliothek_artikel_page.dart';
import 'package:bibliotheks_app/services/email_export_helper.dart';

class MeinePdfsUndQrcodesSeite extends StatefulWidget {
  const MeinePdfsUndQrcodesSeite({super.key});

  @override
  State<MeinePdfsUndQrcodesSeite> createState() => _MeinePdfsUndQrcodesSeiteState();
}

class _MeinePdfsUndQrcodesSeiteState extends State<MeinePdfsUndQrcodesSeite> with SingleTickerProviderStateMixin {
  GoogleSignInAccount? aktuellerUser;
  List<String> ausgewaehlteIds = [];
  late TabController _tabController;
  TextEditingController suchController = TextEditingController();
  String suchbegriff = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    GoogleSignIn().signInSilently().then((user) {
      setState(() {
        aktuellerUser = user;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alleEintraege = Hive.box<PdfEintrag>('pdf_eintraege').values.toList();
    final eigeneEintraege = alleEintraege
        .where((e) => e.uploader.trim().toLowerCase() == aktuellerUser?.email.trim().toLowerCase())
        .toList();

    final gefilterteEintraege = eigeneEintraege.where((e) {
      final titel = e.titel.toLowerCase();
      final text = e.text.toLowerCase();
      return titel.contains(suchbegriff) || text.contains(suchbegriff);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine PDFs & QR-Codes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDFs'),
            Tab(icon: Icon(Icons.qr_code), text: 'QR-Codes'),
          ],
        ),
        actions: [
          if (_tabController.index == 1) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Alle auswählen / Auswahl aufheben',
              onPressed: () {
                final gefilterteIds = gefilterteEintraege.map((e) => e.id).toList();
                setState(() {
                  final sindAlleSchonAusgewaehlt =
                  gefilterteIds.every((id) => ausgewaehlteIds.contains(id));
                  if (sindAlleSchonAusgewaehlt) {
                    ausgewaehlteIds.removeWhere((id) => gefilterteIds.contains(id));
                  } else {
                    for (var id in gefilterteIds) {
                      if (!ausgewaehlteIds.contains(id)) {
                        ausgewaehlteIds.add(id);
                      }
                    }
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.email),
              tooltip: 'Ausgewählte als PDF senden',
              onPressed: () async {
                final ausgewaehlteEintraege = gefilterteEintraege
                    .where((e) => ausgewaehlteIds.contains(e.id))
                    .toList();
                final titelListe = ausgewaehlteEintraege.map((e) => e.titel).toList();
                await sendeQrExportAnEmail(
                  titelListe,
                  aktuellerUser?.email ?? 'fallback@kigaprima.ch',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR-Code-Dokument wird per Mail verschickt.')),
                );
              },
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: suchController,
              decoration: const InputDecoration(
                labelText: 'Suche in Titel & Text...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  suchbegriff = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // PDF-Ansicht
                gefilterteEintraege.isEmpty
                    ? const Center(child: Text('Keine PDFs gefunden.'))
                    : ListView.builder(
                  itemCount: gefilterteEintraege.length,
                  itemBuilder: (context, index) {
                    final eintrag = gefilterteEintraege[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(eintrag.titel),
                        trailing: IconButton(
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BibliothekArtikelPage(eintrag: eintrag),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                // QR-Code-Ansicht
                gefilterteEintraege.isEmpty
                    ? const Center(child: Text('Keine QR-Codes gefunden.'))
                    : ListView.builder(
                  itemCount: gefilterteEintraege.length,
                  itemBuilder: (context, index) {
                    final eintrag = gefilterteEintraege[index];
                    final istAusgewaehlt = ausgewaehlteIds.contains(eintrag.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(eintrag.titel),
                        subtitle: QrImageView(
                          data: 'https://bibliothek.kigaprima.ch/qr/${eintrag.id}',
                          version: QrVersions.auto,
                          size: 120.0,
                        ),
                        trailing: Checkbox(
                          value: istAusgewaehlt,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                ausgewaehlteIds.add(eintrag.id);
                              } else {
                                ausgewaehlteIds.remove(eintrag.id);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
