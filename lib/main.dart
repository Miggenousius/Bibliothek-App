import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/startseite/startseite.dart';
import 'package:bibliotheks_app/models/hive_pdf_model.dart';
import 'package:bibliotheks_app/services/drive_helper.dart';


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

class LibraryApp extends StatefulWidget {
  const LibraryApp({super.key});

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  @override
  void initState() {
    super.initState();
    getOrCreateZentraleAusleihJson(); // ✅ wird nur einmal beim App-Start ausgelöst
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schulbibliothek',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const Startseite(),
    );
  }
}
