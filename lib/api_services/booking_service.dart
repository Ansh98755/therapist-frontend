import 'package:therapist_app/api_services/api_service.dart';
import '../models/booking.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  Future<List<Booking>> getBookings() async {
    final result = await _apiService.getBookings();

    if (result['success'] == true) {
      final data = result['data'];
      List bookingsArray = [];

      if (data is Map<String, dynamic>) {
        bookingsArray = data['data'] ?? data['bookings'] ?? data['results'] ?? [];
      } else if (data is List) {
        bookingsArray = data;
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
