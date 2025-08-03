/*
  Datei: qr_scan_page.dart
  Zweck: Scannt QR-Codes und verarbeitet Ausleihvorgänge über Google Drive
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Seite nutzt die Kamera, um QR-Codes zu scannen.
  Beim Erkennen eines gültigen Codes wird ein Ausleihevorgang erzeugt oder aktualisiert
  und mit dem aktuellen Nutzer verknüpft. Die Daten werden in Google Drive gespeichert.

  Verwendet in:
  - QR-Code-basierte Ausleihe von physischen Bibliotheksobjekten
  - Anbindung an `ausleihe_service.dart` und `google_auth_helper.dart`
*/


import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:bibliotheks_app/services/ausleihe_service.dart';
import 'package:bibliotheks_app/services/google_auth_helper.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bibliotheks_app/pages/ausleihe/ausleihformular.dart';



class QRScanPage extends StatefulWidget {
  final String pdfId;
  final String titel;
  final String verleihEmail;

  const QRScanPage({
    required this.pdfId,
    required this.titel,
    required this.verleihEmail,
    super.key,
  });

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _scanAbgeschlossen = false;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_scanAbgeschlossen) return;

      final code = scanData.code;
      if (code != null) {
        setState(() => _scanAbgeschlossen = true);
        _verarbeiteQRCode(code);
      }
    });
  }

  Future<void> _verarbeiteQRCode(String code) async {
    controller?.pauseCamera();

    print('📦 Gescannter Code: $code');
    print('🎯 Erwartete pdfId: ${widget.pdfId}');

    if (code.trim().contains(widget.pdfId.trim())) {
      print('✅ PDF-ID erkannt, öffne Ausleihformular...');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Ausleihformular(
              pdfId: widget.pdfId,
              titel: widget.titel,
                verleihEmail: widget.verleihEmail,
            ),
          ),
        );
      }
    } else {
      print('❌ QR-Code enthält nicht die erwartete pdfId.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ QR-Code ungültig')),
        );
      }
    }
  }



  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR-Code scannen')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 12,
          borderLength: 30,
          borderWidth: 8,
          cutOutSize: 250,
        ),
      ),
    );
  }
}
