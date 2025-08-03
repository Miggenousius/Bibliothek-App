import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

Future<void> sendeQrExportAnEmail(List<String> titelListe, String empfaengerEmail) async {
  const String endpointUrl = 'https://script.google.com/macros/s/AKfycbwclyUd1Q7iIFGztr5FBR3RpHdJCMcYJ8k3X75BGc7aQO-iAdOteG0CTx2BfrDLiOdwGg/exec';
  final body = jsonEncode({
    'titelListe': titelListe,
    'email': empfaengerEmail,
  });

  debugPrint('📤 Sende an Google Apps Script:\n$body');

  final response = await http.post(
    Uri.parse(endpointUrl),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  debugPrint('📥 Antwort vom Server:\n${response.body}');

  if (response.statusCode == 200 || response.statusCode == 302) {
    debugPrint('✅ QR-Code-Dokument wurde versendet.');
  } else {
    debugPrint('❌ Fehler beim Versand: ${response.statusCode}');
    throw Exception('Fehler beim QR-Code-Versand: ${response.body}');
  }
}
