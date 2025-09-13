class Customer {
  final String name;
  final String phone;
  final String id;

  Customer({required this.name, required this.phone, required this.id});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      id: json['id'].toString(),
    );
  }
}

class Booking {
  final String id;
  final Customer customer;
  final String type;
  final String status;
  final String price;
  final String duration;
  final DateTime? meetDateTime;
  final String displayDate;
  final String time;
  final bool finished;
  final String notes;
  final String link;
  final DateTime? createdAt;

  Booking({
    required this.id,
    required this.customer,
    required this.type,
    required this.status,
    required this.price,
    required this.duration,
    this.meetDateTime,
    required this.displayDate,
    required this.time,
    required this.finished,
    required this.notes,
    required this.link,
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // No customer object, so fallback to "Unknown"
    final customer = Customer(
      name: 'Unknown Client',
      phone: '',
      id: json['customerId']?.toString() ?? '',
    );

    DateTime? parseDateTime(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    String formatDate(String? dateStr) {
      if (dateStr == null) return '';
      try {
        final date = DateTime.parse(dateStr);
        return '${date.day}/${date.month}/${date.year}';
      } catch (_) {
        return '';
      }
    }

    return Booking(
      id: json['_id'].toString(),
      customer: customer,
      type: json['meetStatus'] ?? '',
      status: (json['meetStatus'] ?? '').toString().toLowerCase(),
      price: '',
      duration: '',
      meetDateTime: parseDateTime(json['meetDate']),
      displayDate: formatDate(json['meetDate']),
      time: json['meetTime'] ?? '',
      finished: json['finished'] ?? false,
      notes: '',
      link: json['meetLink'] ?? '',
      createdAt: parseDateTime(json['createdAt']),
    );
  }
}