import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/drive/v3.dart' as drive;

/// Google Sign-In Konfiguration mit benötigten Scopes
final GoogleSignIn googleSignIn = GoogleSignIn(
  clientId: '863090442961-f4j6avtfiem6d7fe8op4s6emaof1f3pi.apps.googleusercontent.com', // <--- hier einsetzen
  scopes: [
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ],
);


Future<({drive.DriveApi driveApi, http.Client client})> googleDriveApiHolen() async {
  final user = await googleSignIn.signIn();
  if (user == null) throw Exception('❌ Kein Benutzer angemeldet.');

  final authHeaders = await user.authHeaders;
  final client = auth.authenticatedClient(
    http.Client(),
    auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        authHeaders['Authorization']!.split(' ').last,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
        [
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/script.external_request',
        ]
    ),
  );

  final driveApi = drive.DriveApi(client);
  return (driveApi: driveApi, client: client);
}
