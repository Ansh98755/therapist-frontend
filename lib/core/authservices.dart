import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _tokenExpiryKey = 'token_expiry';

  // Stream controller for auth state changes.
  // Use onListen to emit the current auth status immediately when a listener subscribes,
  // so that late subscribers (like widgets mounted after a login event) receive the
  // latest value and don't miss transitions.
  static final StreamController<bool>
  _authStateController = StreamController<bool>.broadcast(
    onListen: () async {
      try {
        final current = await AuthService().isLoggedIn();
        print('AuthService.onListen: emitting current auth state: $current');
        // Add current state to stream so subscribers get an immediate value.
        _authStateController.add(current);
      } catch (e) {
        print('AuthService.onListen error: $e');
      }
    },
  );
  static Stream<bool> get authStateStream => _authStateController.stream;

  // Diagnostic helper to check if anyone is listening to auth state
  static bool get hasAuthListeners => _authStateController.hasListener;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Cache for user data to avoid repeated SharedPreferences calls
  Map<String, dynamic>? _cachedUserData;
  String? _cachedToken;
  bool _isInitialized = false;

  Future<bool> saveAuthData(String token, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setString(_authTokenKey, token);
      await prefs.setString(_userDataKey, jsonEncode(userData));
      await prefs.setString(_lastLoginTimeKey, now.toIso8601String());

      final expiryTime = now.add(const Duration(hours: 24));
      await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());

      _cachedToken = token;
      _cachedUserData = userData;
      _isInitialized = true;

      print('Auth data saved successfully');
      final tokenPreview = (token.length > 20)
          ? '${token.substring(0, 20)}...'
          : token;
      print('Token: $tokenPreview');
      print('User data: $userData');

      // Debug the therapist ID immediately after saving
      await debugUserData();

      print('Notifying auth state stream about login success...');
      print('AuthService: has listeners = ${_authStateController.hasListener}');

      // Add a small delay to ensure all data is properly saved and cached
      await Future.delayed(const Duration(milliseconds: 100));

      // Notify listeners about auth state change
      _authStateController.add(true);
      print('AuthService: notify() called');

      print('Auth state notification sent');

      return true;
    } catch (e) {
      print('Error saving auth data: $e');
      return false;
    }
  }

  Future<String?> getAuthToken() async {
    try {
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        return _cachedToken;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);

      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        return token;
      }

      return null;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_cachedUserData != null) return _cachedUserData;

      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);

      if (userDataString != null && userDataString.isNotEmpty) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        _cachedUserData = userData;
        return userData;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> debugUserData() async {
    try {
      final userData = await getUserData();
      print('=== USER DATA DEBUG ===');
      print('Full user data: $userData');

      if (userData != null) {
        print('Available keys: ${userData.keys}');

        // Check all possible ID fields
        final possibleIdFields = [
          'id',
          'therapistId',
          'userId',
          'psychologist_id',
          'doctor_id',
          'therapist_id',
          'user_id',
          'psychologistId',
          'therapistID',
          'userID',
          'ID',
          '_id',
        ];

        for (var field in possibleIdFields) {
          if (userData.containsKey(field)) {
            print(
              '$field: ${userData[field]} (type: ${userData[field].runtimeType})',
            );
          }
        }

        // Check for nested objects
        userData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            print('Nested object $key: ${value.keys}');
            possibleIdFields.forEach((idField) {
              if (value.containsKey(idField)) {
                print('  $key.$idField: ${value[idField]}');
              }
            });
          }
        });
      }
      print('=======================');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  // FIXED: Enhanced therapist ID extraction based on login API response
  Future<String?> getTherapistId() async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        print('Available keys in userData: ${userData.keys}');

        // Based on your login API response, check these specific fields first
        String? therapistId;

        // Check for direct ID fields in the main userData
        therapistId =
            userData['_id']?.toString() ??
            userData['id']?.toString() ??
            userData['therapistId']?.toString() ??
            userData['userId']?.toString() ??
            userData['psychologist_id']?.toString() ??
            userData['doctor_id']?.toString() ??
            userData['therapist_id']?.toString() ??
            userData['user_id']?.toString() ??
            userData['psychologistId']?.toString() ??
            userData['therapistID']?.toString() ??
            userData['userID']?.toString() ??
            userData['ID']?.toString();

        // If still null, check for nested user data in the API response
        if (therapistId == null) {
          // Based on your API structure, check nested objects
          final nestedObjects = [
            userData['data'],
            userData['user'],
            userData['therapist'],
            userData['psychologist'],
            userData['profile'],
          ];

          for (var nestedObj in nestedObjects) {
            if (nestedObj is Map<String, dynamic>) {
              therapistId =
                  nestedObj['_id']?.toString() ??
                  nestedObj['id']?.toString() ??
                  nestedObj['therapistId']?.toString() ??
                  nestedObj['userId']?.toString() ??
                  nestedObj['psychologist_id']?.toString() ??
                  nestedObj['therapist_id']?.toString();

              if (therapistId != null) break;
            }
          }
        }

        print('Retrieved therapist ID: $therapistId');

        // Enhanced debugging if still null
        if (therapistId == null) {
          print('THERAPIST ID STILL NULL - Full debug:');
          print('Raw userData type: ${userData.runtimeType}');
          print('Raw userData: $userData');

          userData.forEach((key, value) {
            print('Key: $key, Value: $value, Type: ${value.runtimeType}');
            if (value is Map<String, dynamic>) {
              print('  Nested keys: ${value.keys}');
            }
          });
        }

        return therapistId;
      }
      print('No user data found');
      return null;
    } catch (e) {
      print('Error getting therapist ID: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      if (!_isInitialized) {
        await _initializeCache();
      }

      final token = await getAuthToken();
      final userData = await getUserData();

      print('Checking login status:');
      print('Token exists: ${token != null && token.isNotEmpty}');
      print('User data exists: ${userData != null}');

      if (token == null || token.isEmpty || userData == null) {
        print('Login check failed: Missing token or user data');
        return false;
      }

      // Check if token is expired
      final isExpired = await _isTokenExpired();
      if (isExpired) {
        print('Token expired, clearing auth data');
        await clearAuthData();
        return false;
      }

      print('User is logged in');
      return true;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  Future<bool> _isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_tokenExpiryKey);

      if (expiryString == null) {
        print('No expiry time found, considering token expired');
        return true;
      }

      final expiryTime = DateTime.parse(expiryString);
      final isExpired = DateTime.now().isAfter(expiryTime);

      print('Token expiry check: ${isExpired ? "EXPIRED" : "VALID"}');
      print('Expiry time: $expiryTime');
      print('Current time: ${DateTime.now()}');

      return isExpired;
    } catch (e) {
      print('Error checking token expiry: $e');
      return true;
    }
  }

  Future<void> _initializeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_authTokenKey);

      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null && userDataString.isNotEmpty) {
        _cachedUserData = json.decode(userDataString) as Map<String, dynamic>;
      }

      _isInitialized = true;
      print('Auth cache initialized');
    } catch (e) {
      print('Error initializing cache: $e');
    }
  }

  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_lastLoginTimeKey);
      await prefs.remove(_tokenExpiryKey);

      // Clear cache
      _cachedToken = null;
      _cachedUserData = null;
      _isInitialized = false;

      print('Auth data cleared');

      // Notify listeners about auth state change
      _authStateController.add(false);
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  Future<bool> validateToken() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        print('Token validation failed: No token');
        return false;
      }

      // Check if token is expired locally first
      if (await _isTokenExpired()) {
        print('Token validation failed: Token expired');
        await clearAuthData();
        return false;
      }

      print('Token validation successful');
      return true;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  // Method to refresh user data from backend
  Future<bool> refreshUserData() async {
    try {
      final token = await getAuthToken();
      final therapistId = await getTherapistId();

      if (token == null || therapistId == null) {
        print('Cannot refresh user data: Missing token or therapist ID');
        return false;
      }

      print('Refreshing user data for therapist ID: $therapistId');

      // Make API call to refresh user data
      final response = await http
          .get(
            Uri.parse(
              'https://niti.nexuserp.co.in/api/getUserProfile/$therapistId',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Refresh user data response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          await saveAuthData(token, data['data']);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error refreshing user data: $e');
      return false;
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _authStateController.close();
  }
}
