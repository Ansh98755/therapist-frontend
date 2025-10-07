class Customer {
  final String id;
  final String name;
  final String phone;

  Customer({required this.id, required this.name, required this.phone});

  factory Customer.fromJson(dynamic json) {
    if (json == null) {
      return Customer(id: '', name: 'Unknown Client', phone: '');
    }

    if (json is String) {
      // If API provides just an ID as a string sometimes
      return Customer(id: json, name: 'Unknown Client', phone: '');
    }

    final id = json['_id']?.toString() ?? '';
    final name = json['fullName'] ?? 'Unknown Client';
    final phone = json['phoneNumber'] ?? '';

    return Customer(id: id, name: name, phone: phone);
  }
}

class Booking {
  final String id;
  final Customer customer;
  final String type; // e.g. 'Booked', 'Rescheduled'
  final String status;
  final String charge;
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
    required this.charge,
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
    DateTime? parseDateTime(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      return DateTime.tryParse(dateStr);
    }

    String formatDate(String? dateStr) {
      if (dateStr == null) return '';
      try {
        final dt = DateTime.parse(dateStr);
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        return '';
      }
    }

    final customerJson = json['customerId'];
    final customer = Customer.fromJson(customerJson);

    return Booking(
      id: json['_id'].toString(),
      customer: customer,
      type: json['meetStatus'] ?? '',
      status: (json['meetStatus'] ?? '').toString().toLowerCase(),
      charge: json['charge']?.toString() ?? '',
      duration: '', // no duration info
      meetDateTime: parseDateTime(json['meetDate']),
      displayDate: formatDate(json['meetDate']),
      time: json['meetTime'] ?? '',
      finished: json['finished'] ?? false,
      notes: '', // no notes info
      link: json['meetLink'] ?? '',
      createdAt: parseDateTime(json['createdAt']),
    );
  }
}
