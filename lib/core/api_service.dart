import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:therapist_app/core/authservices.dart';

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
        // Token expired or invalid
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

  // FIXED: Enhanced login API to handle response structure better
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

      print('Raw login response: ${response.body}');
      print('Response status: ${response.statusCode}');

      // Handle the response according to your API structure
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Based on your API image, the structure should be:
          // { message: "...", data: { ... therapist data ... } }
          if (responseData is Map<String, dynamic>) {
            return {
              'success': true,
              'data': responseData, // Return the entire response
              'message': responseData['message'] ?? 'Login successful',
            };
          } else {
            return {'success': false, 'error': 'Invalid response format'};
          }
        } catch (e) {
          print('JSON parsing error: $e');
          return {'success': false, 'error': 'Failed to parse login response'};
        }
      } else {
        // Handle error responses
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

  // FIXED: Enhanced bookings API to handle better error cases and therapist ID
  Future<Map<String, dynamic>> getBookings({
    bool finished = false,
    String meetDate = '',
    String meetStatus = '',
  }) async {
    try {
      final therapistId = await _authService.getTherapistId();
      if (therapistId == null) {
        print('Cannot get bookings: Therapist ID not found');

        // Try to refresh user data first
        final refreshSuccess = await _authService.refreshUserData();
        if (refreshSuccess) {
          final newTherapistId = await _authService.getTherapistId();
          if (newTherapistId == null) {
            return {
              'success': false,
              'error': 'Therapist ID not found after refresh',
            };
          }
        } else {
          return {
            'success': false,
            'error': 'Therapist ID not found. Please login again.',
          };
        }
      }

      final finalTherapistId = await _authService.getTherapistId();
      print('Fetching bookings for therapist ID: $finalTherapistId');

      // Create request body that matches your backend requirements
      final requestBody = <String, dynamic>{
        'therapistId': finalTherapistId,
        'finished': finished,
      };

      // Only add optional fields if they have values
      if (meetDate.isNotEmpty) {
        requestBody['meetDate'] = meetDate;
      }

      if (meetStatus.isNotEmpty && meetStatus.toLowerCase() != 'all') {
        requestBody['meetStatus'] = meetStatus;
      }

      print('Bookings request body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/getPsychologistHomePage'),
            headers: await _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response);
      print('Bookings result: $result');

      return result;
    } catch (e) {
      print('Get bookings error: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getTherapistById() async {
    try {
      final therapistId = await _authService.getTherapistId();
      if (therapistId == null) {
        return {'success': false, 'error': 'Therapist ID not found'};
      }

      print('Fetching therapist data for ID: $therapistId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/getTherapistById/$therapistId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response);
      print('Get therapist result: $result');

      return result;
    } catch (e) {
      print('Get therapist error: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Update user profile picture
  Future<Map<String, dynamic>> updateUserProfilePicture(
    String profilePicture,
  ) async {
    try {
      final requestBody = {'profile_picture': profilePicture};

      final response = await http
          .post(
            Uri.parse('$baseUrl/UpdateUserProfilePicture'),
            headers: await _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final therapistId = await _authService.getTherapistId();
      if (therapistId == null) {
        return {'success': false, 'error': 'Therapist ID not found'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/getUserProfile/$therapistId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final therapistId = await _authService.getTherapistId();
      if (therapistId == null) {
        return {'success': false, 'error': 'Therapist ID not found'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/getAnalytics/$therapistId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Cancel booking
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

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final therapistId = await _authService.getTherapistId();
      if (therapistId == null) {
        return {'success': false, 'error': 'Therapist ID not found'};
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/updateProfile/$therapistId'),
            headers: await _getHeaders(),
            body: json.encode(profileData),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Get community posts
  Future<Map<String, dynamic>> getCommunityPosts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/getCommunityPosts'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  // Create community post
  Future<Map<String, dynamic>> createCommunityPost(
    Map<String, dynamic> postData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/createCommunityPost'),
            headers: await _getHeaders(),
            body: json.encode(postData),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please check your connection.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection.';
    } else if (error.toString().contains('HandshakeException')) {
      return 'Connection error. Please try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
