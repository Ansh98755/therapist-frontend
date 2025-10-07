import 'package:therapist_app/api_services/api_service.dart';
import '../models/booking.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  Future<List<Booking>> getBookings() async {
    final result = await _apiService.getBookings();

    if (result['success'] == true) {
      final parsedData = result['data'];
      List<dynamic> bookingsArray = [];

      // Your API response includes 'data' with 'data' array inside it OR just an array
      if (parsedData is Map<String, dynamic>) {
        // If your ApiService returns entire parsed response inside 'data' key
        bookingsArray = parsedData['data'] ?? [];
      } else if (parsedData is List) {
        bookingsArray = parsedData;
      }

      return bookingsArray
          .whereType<Map<String, dynamic>>()
          .map((json) => Booking.fromJson(json))
          .toList();
    } else {
      throw Exception(result['error'] ?? 'Failed to load bookings');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final result = await _apiService.cancelBooking(bookingId);
    if (result['success'] != true) {
      throw Exception(result['error'] ?? 'Failed to cancel booking');
    }
  }
}
