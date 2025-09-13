import 'package:flutter/material.dart';
import '../api_services/booking_service.dart';
import '../models/booking.dart';

class BookingsProvider with ChangeNotifier {
  final BookingService _service = BookingService();

  List<Booking> _bookings = [];
  bool _loading = false;
  String _errorMessage = '';
  String _selectedFilter = 'All';
  String _searchQuery = '';

  List<Booking> get bookings => _bookings;
  bool get loading => _loading;
  String get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  Future<void> loadBookings() async {
    _loading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _bookings = await _service.getBookings();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Booking> get filteredBookings {
    var filtered = _bookings;
    if (_selectedFilter.toLowerCase() != 'all') {
      filtered = filtered.where((b) {
        if (_selectedFilter.toLowerCase() == 'completed') {
          return b.finished || b.status == 'completed';
        }
        return b.status.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        return b.customer.name.toLowerCase().contains(q) ||
            b.type.toLowerCase().contains(q) ||
            b.status.toLowerCase().contains(q);
      }).toList();
    }
    filtered.sort((a, b) {
      if (a.meetDateTime == null) return 1;
      if (b.meetDateTime == null) return -1;
      return b.meetDateTime!.compareTo(a.meetDateTime!);
    });
    return filtered;
  }
}
