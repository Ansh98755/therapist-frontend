import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class SharedPrefService {
  SharedPrefService._internal();
  static final SharedPrefService _instance = SharedPrefService._internal();
  factory SharedPrefService() => _instance;

  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _tokenExpiryKey = 'token_expiry';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> setString(String key, String value) async =>
      (await _prefs).setString(key, value);
  Future<String?> getString(String key) async => (await _prefs).getString(key);
  Future<void> remove(String key) async => (await _prefs).remove(key);

  Future<void> saveToken(String token) async {
    await setString(_authTokenKey, token);
  }

  Future<String?> getToken() => getString(_authTokenKey);

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await setString(_userDataKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await getString(_userDataKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastLogin(DateTime dt) async {
    await setString(_lastLoginTimeKey, dt.toIso8601String());
  }

  Future<void> saveTokenExpiry(DateTime dt) async {
    await setString(_tokenExpiryKey, dt.toIso8601String());
  }

  Future<DateTime?> getTokenExpiry() async {
    final s = await getString(_tokenExpiryKey);
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    final p = await _prefs;
    await p.remove(_authTokenKey);
    await p.remove(_userDataKey);
    await p.remove(_lastLoginTimeKey);
    await p.remove(_tokenExpiryKey);
  }
}
