import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _tokenExpiryKey = 'token_expiry';

  // Stream controller for auth state changes
  static final StreamController<bool> _authStateController = 
      StreamController<bool>.broadcast(
    onListen: () async {
      try {
        final current = await AuthService().isLoggedIn();
        print('AuthService.onListen: emitting current auth state: $current');
        _authStateController.add(current);
      } catch (e) {
        print('AuthService.onListen error: $e');
      }
    },
  );
  static Stream<bool> get authStateStream => _authStateController.stream;
  static bool get hasAuthListeners => _authStateController.hasListener;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Cache for user data
  Map<String, dynamic>? _cachedUserData;
  String? _cachedToken;
  String? _cachedTherapistId;
  bool _isInitialized = false;

  Future<bool> saveAuthData(String token, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setString(_authTokenKey, token);
      await prefs.setString(_userDataKey, jsonEncode(userData));
      await prefs.setString(_lastLoginTimeKey, now.toIso8601String());

      // Set token expiry based on JWT expiry or default to 24 hours
      DateTime expiryTime;
      try {
        final jwtExpiry = _getJWTExpiryTime(token);
        expiryTime = jwtExpiry ?? now.add(const Duration(hours: 24));
      } catch (e) {
        print('Error getting JWT expiry, using default: $e');
        expiryTime = now.add(const Duration(hours: 24));
      }
      
      await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());

      _cachedToken = token;
      _cachedUserData = userData;
      _isInitialized = true;

      // Extract and cache therapist ID
      _cachedTherapistId = await _extractTherapistId();

      print('Auth data saved successfully');
      print('Token: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}');
      print('User data keys: ${userData.keys}');
      print('Cached therapist ID: $_cachedTherapistId');

      // Notify auth state change
      await Future.delayed(const Duration(milliseconds: 100));
      _authStateController.add(true);
      print('Auth state notification sent');

      return true;
    } catch (e) {
      print('Error saving auth data: $e');
      return false;
    }
  }

  // Extract expiry time from JWT token
  DateTime? _getJWTExpiryTime(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      
      // Add padding if needed
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedPayload = utf8.decode(decodedBytes);
      final payloadMap = json.decode(decodedPayload);

      final exp = payloadMap['exp'];
      if (exp != null && exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }

      return null;
    } catch (e) {
      print('Error extracting JWT expiry: $e');
      return null;
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
      final token = await getAuthToken();
      
      print('=== USER DATA DEBUG ===');
      print('Full user data: $userData');
      print('Token: ${token != null && token.length > 20 ? '${token.substring(0, 20)}...' : token}');

      if (userData != null) {
        print('Available keys: ${userData.keys}');
        
        userData.forEach((key, value) {
          print('$key: $value (${value.runtimeType})');
          if (value is Map<String, dynamic>) {
            print('  Nested keys: ${value.keys}');
            value.forEach((nestedKey, nestedValue) {
              print('  $nestedKey: $nestedValue (${nestedValue.runtimeType})');
            });
          }
        });
      }

      // Debug JWT token
      if (token != null) {
        try {
          final jwtPayload = _parseJWTPayload(token);
          if (jwtPayload != null) {
            print('JWT Payload: $jwtPayload');
            print('JWT Keys: ${jwtPayload.keys}');
          }
        } catch (e) {
          print('Error parsing JWT for debug: $e');
        }
      }

      print('=======================');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  // Parse JWT payload
  Map<String, dynamic>? _parseJWTPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      
      // Add padding if needed
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedPayload = utf8.decode(decodedBytes);
      return json.decode(decodedPayload) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing JWT payload: $e');
      return null;
    }
  }

  // ENHANCED: Better therapist ID extraction with JWT parsing
  Future<String?> getTherapistId() async {
    try {
      // Return cached therapist ID if available
      if (_cachedTherapistId != null && _cachedTherapistId!.isNotEmpty) {
        print('Returning cached therapist ID: $_cachedTherapistId');
        return _cachedTherapistId;
      }

      // Extract therapist ID
      _cachedTherapistId = await _extractTherapistId();
      
      if (_cachedTherapistId != null && _cachedTherapistId!.isNotEmpty) {
        print('Extracted and cached therapist ID: $_cachedTherapistId');
        return _cachedTherapistId;
      }

      print('THERAPIST ID EXTRACTION FAILED');
      await debugUserData(); // Debug when extraction fails
      return null;
    } catch (e) {
      print('Error getting therapist ID: $e');
      return null;
    }
  }

  // Extract therapist ID from multiple sources
  Future<String?> _extractTherapistId() async {
    try {
      String? therapistId;

      // Priority 1: Extract from JWT token
      final token = await getAuthToken();
      if (token != null && token.isNotEmpty) {
        final jwtPayload = _parseJWTPayload(token);
        if (jwtPayload != null) {
          print('JWT Payload keys: ${jwtPayload.keys}');
          
          // Check common JWT fields for therapist ID
          final jwtFields = [
            'therapistId', 'therapist_id', 'psychologistId', 
            'psychologist_id', 'userId', 'user_id', 'id', 'sub'
          ];

          for (final field in jwtFields) {
            if (jwtPayload[field] != null) {
              therapistId = jwtPayload[field].toString();
              print('Found therapist ID in JWT field "$field": $therapistId');
              return therapistId;
            }
          }
        }
      }

      // Priority 2: Extract from user data
      final userData = await getUserData();
      if (userData != null) {
        print('Extracting therapist ID from userData keys: ${userData.keys}');

        // Check direct fields
        final directFields = [
          '_id', 'id', 'therapistId', 'psychologistId', 'userId', 
          'therapist_id', 'psychologist_id', 'user_id',
          'therapistID', 'psychologistID', 'userID', 'ID'
        ];

        for (final field in directFields) {
          if (userData[field] != null) {
            therapistId = userData[field].toString();
            print('Found therapist ID in userData field "$field": $therapistId');
            return therapistId;
          }
        }

        // Check nested objects
        final nestedObjectKeys = ['data', 'user', 'therapist', 'psychologist', 'profile', 'therapistData'];
        
        for (final objKey in nestedObjectKeys) {
          if (userData[objKey] is Map<String, dynamic>) {
            final nestedObj = userData[objKey] as Map<String, dynamic>;
            print('Checking nested $objKey object keys: ${nestedObj.keys}');
            
            for (final field in directFields) {
              if (nestedObj[field] != null) {
                therapistId = nestedObj[field].toString();
                print('Found therapist ID in $objKey.$field: $therapistId');
                return therapistId;
              }
            }
          }
        }
      }

      print('THERAPIST ID NOT FOUND in any source');
      return null;
    } catch (e) {
      print('Error extracting therapist ID: $e');
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

      // Check token expiry
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

      // Extract and cache therapist ID
      _cachedTherapistId = await _extractTherapistId();

      _isInitialized = true;
      print('Auth cache initialized');
      print('Cached therapist ID: $_cachedTherapistId');
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
      _cachedTherapistId = null;
      _isInitialized = false;

      print('Auth data cleared');
      _authStateController.add(false);
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  Future<bool> validateToken() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      if (await _isTokenExpired()) {
        await clearAuthData();
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  Future<String?> refreshTherapistId() async {
    try {
      print('Force refreshing therapist ID...');
      _cachedTherapistId = null; // Clear cache
      _cachedTherapistId = await _extractTherapistId();
      print('Refreshed therapist ID: $_cachedTherapistId');
      return _cachedTherapistId;
    } catch (e) {
      print('Error refreshing therapist ID: $e');
      return null;
    }
  }

  void dispose() {
    _authStateController.close();
  }
}