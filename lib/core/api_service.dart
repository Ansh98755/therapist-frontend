import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:therapist_app/core/authservices.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl = "https://niti.nexuserp.co.in/api";
  static final AuthService _authService = AuthService();

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await _authService.getAuthToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Success',
        };
      } else if (response.statusCode == 401) {
        print('Unauthorized request - clearing auth data');
        _authService.clearAuthData();
        return {
          'success': false,
          'error': 'Authentication failed. Please login again.',
          'code': 401,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Server error occurred',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error parsing response: $e');
      return {
        'success': false,
        'error': 'Failed to parse response',
        'code': response.statusCode,
      };
    }
  }

  // FIXED: Enhanced login method with JWT token parsing
  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final requestBody = {
        "type": 1,
        "phoneNumber": phoneNumber,
        "password": password,
      };

      print('Login request URL: $baseUrl/LoginTherapistProfile');
      print('Login request body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/LoginTherapistProfile'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          if (responseData is Map<String, dynamic>) {
            // Extract token and decode it to get therapist ID
            String? token =
                responseData['token'] ??
                responseData['accessToken'] ??
                responseData['authToken'] ??
                responseData['access_token'];

            Map<String, dynamic> userData = {};

            // If we have user data in response, use it
            if (responseData['data'] != null &&
                responseData['data'] is Map<String, dynamic>) {
              userData = Map<String, dynamic>.from(responseData['data']);
            } else {
              // Use the entire response as user data
              userData = Map<String, dynamic>.from(responseData);
              userData.remove('message');
              userData.remove('status');
              userData.remove('success');
            }

            // IMPORTANT: Parse JWT token to extract therapist ID
            if (token != null && token.isNotEmpty) {
              try {
                final therapistId = _parseTherapistIdFromJWT(token);
                if (therapistId != null) {
                  // Add therapist ID to user data for easy access
                  userData['therapistId'] = therapistId;
                  userData['_id'] =
                      therapistId; // Also add as _id for compatibility
                  print('Extracted therapist ID from JWT: $therapistId');
                }
              } catch (e) {
                print('Error parsing JWT: $e');
              }
            }

            print('Final user data keys: ${userData.keys}');
            print('Final user data: $userData');

            return {
              'success': true,
              'data': userData,
              'token': token,
              'message': responseData['message'] ?? 'Login successful',
            };
          } else {
            return {'success': false, 'error': 'Invalid response format'};
          }
        } catch (e) {
          print('JSON parsing error: $e');
          return {
            'success': false,
            'error': 'Failed to parse login response: $e',
          };
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error':
                errorData['message'] ?? errorData['error'] ?? 'Login failed',
            'code': response.statusCode,
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Login failed with status ${response.statusCode}',
            'code': response.statusCode,
          };
        }
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Helper method to parse therapist ID from JWT token
  String? _parseTherapistIdFromJWT(String token) {
    try {
      // JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
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

      print('JWT Payload: $payloadMap');

      // Extract therapist ID from different possible fields
      return payloadMap['therapistId'] ??
          payloadMap['therapist_id'] ??
          payloadMap['psychologistId'] ??
          payloadMap['userId'] ??
          payloadMap['user_id'] ??
          payloadMap['id'] ??
          payloadMap['sub'];
    } catch (e) {
      print('Error parsing JWT: $e');
      return null;
    }
  }

  // FIXED: GET request for getTherapistById
  Future<Map<String, dynamic>> getTherapistById() async {
    try {
      // Just make sure we have a valid auth token (therapist ID will be extracted from JWT on backend)
      final token = await _authService.getAuthToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'error': 'Authentication token not found'};
      }

      print('Getting therapist profile using JWT token');
      print('Request URL: $baseUrl/getTherapistById');
      print('Has auth token: ${token.length > 20 ? "Yes" : "No"}');

      final response = await http
          .get(
            Uri.parse('$baseUrl/getTherapistById'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('Get therapist by ID error: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // FIXED: Updated getPsychologistHomePage with optional parameters
  Future<Map<String, dynamic>> getBookings({
    bool? finished,
    String? meetDate,
    String? meetStatus,
  }) async {
    try {
      final therapistId = await _authService.getTherapistId();

      if (therapistId == null || therapistId.isEmpty) {
        return {
          'success': false,
          'error': 'Therapist ID not found. Please login again.',
        };
      }

      final requestBody = <String, dynamic>{'therapistId': therapistId};

      if (finished != null) {
        requestBody['finished'] = finished;
        print('📌 Filter: finished = $finished');
      }

      if (meetDate != null && meetDate.isNotEmpty) {
        requestBody['meetDate'] = meetDate;
        print('📌 Filter: meetDate = $meetDate');
      }

      if (meetStatus != null &&
          meetStatus.isNotEmpty &&
          meetStatus.toLowerCase() != 'all') {
        requestBody['meetStatus'] = meetStatus;
        print('📌 Filter: meetStatus = $meetStatus');
      }

      print('🌐 API Request Details:');
      print('   URL: $baseUrl/getPsychologistHomePage');
      print('   Method: POST');
      print('   Body: $requestBody');
      print('   Headers: ${await _getHeaders()}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/getPsychologistHomePage'),
            headers: await _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 API Response Details:');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Raw Body: ${response.body}');

      // Parse JSON response
      Map<String, dynamic> parsedData;
      try {
        parsedData = json.decode(response.body);
        print('✅ JSON parsing successful');
        print('   Parsed data keys: ${parsedData.keys.toList()}');
        print('   Full parsed data: $parsedData');
      } catch (e) {
        print('❌ JSON parsing failed: $e');
        return {'success': false, 'error': 'Failed to parse API response: $e'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ API call successful');

        // Check if response has the expected structure
        if (parsedData.containsKey('apiSuccess') &&
            parsedData.containsKey('resSuccess') &&
            parsedData.containsKey('data')) {
          print(
            '✅ Response has expected structure (apiSuccess, resSuccess, data)',
          );
          print('   apiSuccess: ${parsedData['apiSuccess']}');
          print('   resSuccess: ${parsedData['resSuccess']}');
          print('   message: ${parsedData['message']}');

          var dataArray = parsedData['data'];
          if (dataArray is List) {
            print('✅ Data is array with ${dataArray.length} items');
            if (dataArray.isNotEmpty) {
              print('   First item: ${dataArray[0]}');
              if (dataArray[0] is Map<String, dynamic>) {
                var firstItem = dataArray[0] as Map<String, dynamic>;
                print('   First item keys: ${firstItem.keys.toList()}');
              }
            }
          } else {
            print('❌ Data is not an array: ${dataArray.runtimeType}');
          }

          return {
            'success': true,
            'data': parsedData, // Return the entire parsed response
            'message': parsedData['message'] ?? 'Success',
          };
        } else {
          print('⚠️ Response does not have expected structure');
          print('Available keys: ${parsedData.keys.toList()}');

          // Return anyway, let the HomeScreen handle it
          return {
            'success': true,
            'data': parsedData,
            'message': parsedData['message'] ?? 'Success',
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized request - clearing auth data');
        _authService.clearAuthData();
        return {
          'success': false,
          'error': 'Authentication failed. Please login again.',
          'code': 401,
        };
      } else {
        print('❌ API error with status: ${response.statusCode}');
        return {
          'success': false,
          'error':
              parsedData['message'] ??
              parsedData['error'] ??
              'Server error occurred',
          'code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      print('❌ API Exception: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // NEW: Update user profile picture (Form Data)
  Future<Map<String, dynamic>> updateUserProfilePicture(File imageFile) async {
    try {
      final therapistId = await _authService.getTherapistId();
      if (therapistId == null || therapistId.isEmpty) {
        return {'success': false, 'error': 'Therapist ID not found'};
      }

      print('Updating profile picture for therapist ID: $therapistId');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/UpdateUserProfilePicture'),
      );

      // Add headers
      request.headers.addAll(await _getMultipartHeaders());

      // Add the image file with correct field name
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture', // This should match what your backend expects
          imageFile.path,
        ),
      );

      // Add therapist ID if required by your backend
      request.fields['therapistId'] = therapistId;

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('Profile picture update response status: ${response.statusCode}');
      print('Profile picture update response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('Update profile picture error: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateTherapistProfile({
    String? fullName,
    String? gender,
    String? meetLink,
    String? experience,
    String? expertise,
    String? languages,
    String? qualifications,
    String? charge,
    String? availability,
    String? message,
  }) async {
    try {
      final therapistId = await _authService.getTherapistId();
      if (therapistId == null || therapistId.isEmpty) {
        return {'success': false, 'error': 'Therapist ID not found'};
      }

      print('Updating therapist profile for ID: $therapistId');

      final requestBody = <String, dynamic>{
        'therapistId': therapistId, // ADD THIS - most likely missing!
      };

      // Map frontend field names to backend API field names
      if (fullName != null && fullName.isNotEmpty) {
        requestBody['fullname'] =
            fullName; // API uses 'fullname' not 'fullName'
      }
      if (gender != null && gender.isNotEmpty) {
        requestBody['gender'] = gender;
      }
      if (meetLink != null && meetLink.isNotEmpty) {
        requestBody['meetLink'] = meetLink;
      }
      if (experience != null && experience.isNotEmpty) {
        // Convert to number if possible
        try {
          requestBody['experience'] = int.parse(experience);
        } catch (e) {
          requestBody['experience'] = experience;
        }
      }
      if (expertise != null && expertise.isNotEmpty) {
        // Convert comma-separated string to array if needed by API
        if (expertise.contains(',')) {
          requestBody['expertise'] = expertise
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          requestBody['expertise'] = [expertise.trim()];
        }
      }
      if (languages != null && languages.isNotEmpty) {
        // Convert comma-separated string to array if needed by API
        if (languages.contains(',')) {
          requestBody['languages'] = languages
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          requestBody['languages'] = [languages.trim()];
        }
      }
      if (qualifications != null && qualifications.isNotEmpty) {
        requestBody['qualifications'] = qualifications;
      }
      if (charge != null && charge.isNotEmpty) {
        // Convert to number if possible
        try {
          requestBody['charge'] = int.parse(charge);
        } catch (e) {
          requestBody['charge'] = charge;
        }
      }
      if (availability != null && availability.isNotEmpty) {
        requestBody['availability'] = availability;
      }
      if (message != null && message.isNotEmpty) {
        requestBody['message'] = message;
      }

      print('Update profile request body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/updateTherapistProfile'),
            headers: await _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('Update therapist profile error: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Helper methods for different booking filters
  Future<Map<String, dynamic>> getAllBookings() async {
    return await getBookings();
  }

  Future<Map<String, dynamic>> getCompletedBookings() async {
    return await getBookings(finished: true);
  }

  Future<Map<String, dynamic>> getPendingBookings() async {
    return await getBookings(finished: false);
  }

  Future<Map<String, dynamic>> getBookingsByStatus(String status) async {
    return await getBookings(meetStatus: status);
  }

  Future<Map<String, dynamic>> getBookingsByDate(String date) async {
    return await getBookings(meetDate: date);
  }

  // Cancel booking method
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      print('Cancelling booking ID: $bookingId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/cancelBooking'),
            headers: await _getHeaders(),
            body: json.encode({'bookingId': bookingId}),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      print('Cancel booking error: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // DEPRECATED: Keep for backward compatibility but use getTherapistById instead
  Future<Map<String, dynamic>> getUserProfile() async {
    print('getUserProfile is deprecated, using getTherapistById instead');
    return await getTherapistById();
  }

  // DEPRECATED: Use updateTherapistProfile instead
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    print('updateProfile is deprecated, use updateTherapistProfile instead');
    return await updateTherapistProfile(
      fullName: profileData['fullName'],
      gender: profileData['gender'],
      meetLink: profileData['meetLink'],
      experience: profileData['experience'],
      expertise: profileData['expertise'],
      languages: profileData['languages'],
      qualifications: profileData['qualifications'],
      charge: profileData['charge'],
      availability: profileData['availability'],
      message: profileData['message'],
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please check your connection.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection.';
    } else if (error.toString().contains('HandshakeException')) {
      return 'Connection error. Please try again.';
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }
}
