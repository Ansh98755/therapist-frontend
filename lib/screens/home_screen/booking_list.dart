import 'package:flutter/material.dart';
import '../../models/booking.dart';
import 'booking_card.dart';

class BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final Function(Booking) onBookingTap;
  final Function(Booking) onJoinMeetingTap;

  const BookingList({
    Key? key,
    required this.bookings,
    required this.onBookingTap,
    required this.onJoinMeetingTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          onTap: () => onBookingTap(booking),
          onJoinMeeting: () => onJoinMeetingTap(booking),
        );
      },
    );
  }
}
