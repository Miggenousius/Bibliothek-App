import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/startseite/startseite.dart';
import 'package:bibliotheks_app/models/hive_pdf_model.dart';

// 🔑 Wichtig für globale Snackbar-Navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(PdfEintragAdapter());
  await Hive.openBox('bibliothek_artikel');
  await Hive.openBox<PdfEintrag>('pdf_eintraege');
  await Hive.openBox<String>('favoriten');

  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schulbibliothek',
      navigatorKey: navigatorKey, // 📌 Snackbar- und Navigationszugriff
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const Startseite(), // 👉 falls Startseite auch const-fähig ist
    );
  }
}
