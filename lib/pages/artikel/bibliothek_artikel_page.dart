import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import '../../models/hive_pdf_model.dart';
import '../pdf/pdf_webview.dart';

class BibliothekArtikelPage extends StatefulWidget {
  final PdfEintrag eintrag;

  const BibliothekArtikelPage({super.key, required this.eintrag});

  @override
  State<BibliothekArtikelPage> createState() => _BibliothekArtikelPageState();
}

class _BibliothekArtikelPageState extends State<BibliothekArtikelPage> {
  bool istFavorit = false;

  @override
  void initState() {
    super.initState();
    final favoritenBox = Hive.box<String>('favoriten');
    istFavorit = favoritenBox.containsKey(widget.eintrag.id);
  }

  void toggleFavorit() {
    final favoritenBox = Hive.box<String>('favoriten');

    setState(() {
      if (istFavorit) {
        favoritenBox.delete(widget.eintrag.id);
      } else {
        favoritenBox.put(widget.eintrag.id, widget.eintrag.titel);
      }
      istFavorit = !istFavorit;
    });
  }

  void downloadPdf() async {
    final url = widget.eintrag.pdfUrl;
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF konnte nicht geöffnet werden')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eintrag = widget.eintrag;

    return Scaffold(
      appBar: AppBar(
        title: Text(eintrag.titel),
        actions: [
          IconButton(
            icon: Icon(istFavorit ? Icons.star : Icons.star_border),
            tooltip: istFavorit ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
            onPressed: toggleFavorit,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'PDF herunterladen',
            onPressed: downloadPdf,
          ),
        ],
      ),
      body: PdfWebViewPage(driveUrl: eintrag.pdfUrl),
    );
  }
}
