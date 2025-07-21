/*
  Datei: pdf_webview.dart
  Zweck: Anzeige eines PDF-Dokuments über eingebettete Google-Drive-Vorschau im WebView
  Autor: Michi Zumbrunnen
  Letzte Änderung: 05. Juni 2025

  Beschreibung:
  Diese Seite zeigt ein PDF, das in Google Drive gespeichert ist, über eine WebView an.
  Der Link wird automatisch in eine einbettbare Vorschau-URL umgewandelt.
  JavaScript ist aktiviert, damit das PDF korrekt dargestellt wird.

  Verwendet in:
  - Detailansicht eines Bibliothekseintrags (`bibliothek_artikel.dart`)
  - Anzeige von PDFs innerhalb der App ohne externen Viewer
*/


import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';


class PdfWebViewPage extends StatelessWidget {
  final String driveUrl;

  const PdfWebViewPage({super.key, required this.driveUrl});

  /// Wandelt Google-Drive-Link in einen direkt eingebetteten Vorschau-Link
  String getViewerUrl(String url) {
    if (url.contains('/view')) {
      return url.replaceAll('/view', '/preview');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final viewerUrl = getViewerUrl(driveUrl);
    print('🔍 Lade in WebView: $viewerUrl');

    return WebViewWidget(
      controller: WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(viewerUrl)),
    );
  }
}