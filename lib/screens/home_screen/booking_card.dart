import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../utils/color_constants/color_constants.dart';
import '../../utils/status_helpers/status_helpers.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onJoinMeeting;
  const BookingCard({
    Key? key,
    required this.booking,
    this.onTap,
    this.onJoinMeeting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final customerName = booking.customer.name.isNotEmpty
        ? booking.customer.name
        : 'Client';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.customer.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryBrownColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(booking.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: getStatusTextColor(booking.status),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                if (booking.customer.phone.isNotEmpty) ...[
                  Text(
                    booking.customer.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorConstants.color666666,
                    ),
                  ),
                  SizedBox(height: 2),
                ],

                Text(
                  'Therapist Session',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorConstants.primaryOrangeColor,
                  ),
                ),

                SizedBox(height: 16),

                // Date and Time Row
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: ColorConstants.color666666),
                    SizedBox(width: 8),
                    Text(
                      booking.displayDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.blackColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.access_time,
                        size: 16, color: ColorConstants.color666666),
                    SizedBox(width: 8),
                    Text(
                      booking.time,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.blackColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.currency_rupee,
                        size: 16, color: ColorConstants.color666666),
                    SizedBox(width: 6),
                    Text(
                      '${booking.charge.isNotEmpty ? booking.charge : '0'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.blackColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.videocam,
                        size: 16, color: ColorConstants.color666666),
                    SizedBox(width: 8),
                    Text(
                      booking.type,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.blackColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (booking.link.isNotEmpty) ...[
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: onJoinMeeting,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ColorConstants.colorF9F9F9,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.link,
                              size: 16, color: ColorConstants.primaryBrownColor),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.link,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorConstants.blueColor,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.link_off,
                          size: 16, color: ColorConstants.grey),
                      SizedBox(width: 8),
                      Text(
                        'Meeting link will be provided soon',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstants.hintColor ?? Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
