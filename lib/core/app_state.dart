import 'dart:async';
import 'package:therapist_app/core/authservices.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final AuthService _authService = AuthService();

  // Stream controllers for different data types
  final StreamController<Map<String, dynamic>?> _userDataController =
      StreamController<Map<String, dynamic>?>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _bookingsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _analyticsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<Map<String, dynamic>?> get userDataStream => _userDataController.stream;
  Stream<List<Map<String, dynamic>>> get bookingsStream => _bookingsController.stream;
  Stream<Map<String, dynamic>> get analyticsStream => _analyticsController.stream;

  // Cached data
  Map<String, dynamic>? _cachedUserData;
  List<Map<String, dynamic>> _cachedBookings = [];
  Map<String, dynamic> _cachedAnalytics = {};

  // Getters for cached data
  Map<String, dynamic>? get cachedUserData => _cachedUserData;
  List<Map<String, dynamic>> get cachedBookings => _cachedBookings;
  Map<String, dynamic> get cachedAnalytics => _cachedAnalytics;

  // Initialize app state
  Future<void> initialize() async {
    try {
      print('Initializing AppState...');
      
      // Load cached user data
      _cachedUserData = await _authService.getUserData();
      if (_cachedUserData != null) {
        print('Loaded cached user data: $_cachedUserData');
        _userDataController.add(_cachedUserData);
      } else {
        print('No cached user data found');
      }
    } catch (e) {
      print('Error initializing app state: $e');
    }
  }

  // Update user data
  void updateUserData(Map<String, dynamic>? userData) {
    print('Updating user data: $userData');
    _cachedUserData = userData;
    _userDataController.add(userData);
  }

  // Update bookings data
  void updateBookings(List<Map<String, dynamic>> bookings) {
    print('Updating bookings: ${bookings.length} items');
    _cachedBookings = bookings;
    _bookingsController.add(bookings);
  }

  // Update analytics data
  void updateAnalytics(Map<String, dynamic> analytics) {
    print('Updating analytics: $analytics');
    _cachedAnalytics = analytics;
    _analyticsController.add(analytics);
  }

  // Clear all cached data (on logout)
  void clearAllData() {
    print('Clearing all app state data');
    _cachedUserData = null;
    _cachedBookings = [];
    _cachedAnalytics = {};
    _userDataController.add(null);
    _bookingsController.add([]);
    _analyticsController.add({});
  }

  // Dispose resources
  void dispose() {
    print('Disposing AppState');
    _userDataController.close();
    _bookingsController.close();
    _analyticsController.close();
  }
}