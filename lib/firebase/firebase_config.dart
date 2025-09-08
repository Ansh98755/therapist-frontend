import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static String get appId => dotenv.env['APP_ID'] ?? '';
  static String get messagingSenderId =>
      dotenv.env['MESSAGING_SENDER_ID'] ?? '';
  static String get projectId => dotenv.env['PROJECT_ID'] ?? '';
  static String get storageBucket => dotenv.env['STORAGE_BUCKET'] ?? '';
}

