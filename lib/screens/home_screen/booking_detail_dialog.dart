import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../utils/color_constants/color_constants.dart';

class BookingDetailDialog extends StatelessWidget {
  final Booking booking;
  final VoidCallback onJoinMeeting;

  const BookingDetailDialog({
    Key? key,
    required this.booking,
    required this.onJoinMeeting,
  }) : super(key: key);

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: ColorConstants.primaryBrownColor,
            )),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text('Booking Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: ColorConstants.primaryBrownColor,
                      )),
                  IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context))
                ],
              ),
              SizedBox(height: 20),
              _buildDetailSection('Client Information', [
                _buildDetailRow('Name', booking.customer.name),
                if (booking.customer.phone.isNotEmpty)
                  _buildDetailRow('Phone', booking.customer.phone),
                _buildDetailRow('Client ID', booking.customer.id),
              ]),
              SizedBox(height: 16),
              _buildDetailSection('Session Details', [
                _buildDetailRow('Date', booking.displayDate),
                _buildDetailRow('Time', booking.time),
                _buildDetailRow('Type', booking.type),
                _buildDetailRow('Duration', booking.duration),
                _buildDetailRow('Fee', '₹${booking.price}'),
                _buildDetailRow('Status', booking.status),
                if (booking.createdAt != null)
                  _buildDetailRow(
                      'Booked On',
                      '${booking.createdAt!.day}/${booking.createdAt!.month}/${booking.createdAt!.year}'),
              ]),
              if (booking.notes.isNotEmpty) ...[
                SizedBox(height: 16),
                _buildDetailSection('Notes', [
                  Text(
                    booking.notes,
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14),
                  ),
                ]),
              ],
              if (booking.link.isNotEmpty) ...[
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onJoinMeeting();
                  },
                  icon: Icon(Icons.videocam, color: Colors.white),
                  label: Text('Join Meeting',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6B35),
                    padding:
                    EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
