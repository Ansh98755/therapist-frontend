import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/shared_pref.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../utils/color_constants/color_constants.dart';
import 'booking_detail_dialog.dart';
import 'booking_list.dart';
import 'meeting_link_launcher.dart';
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  String fullName = 'Therapist';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<BookingsProvider>();
      provider.loadBookings();

      final storedFullName = await SharedPrefService().getFullName();
      if (storedFullName != null && storedFullName.isNotEmpty) {
        setState(() {
          fullName = storedFullName;
        });
      }
    });

    _searchController.addListener(() {
      final provider = context.read<BookingsProvider>();
      provider.setSearchQuery(_searchController.text);
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (_) => BookingDetailDialog(
        booking: booking,
        onJoinMeeting: () => _launchMeetingLink(booking.link),
      ),
    );
  }

  Future<void> _launchMeetingLink(String link) async {
    await launchMeetingLink(context, link);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConstants.whiteColor,
        elevation: 0,
        title: Text(
          'Hello ${fullName}',
          style: TextStyle(
            color: ColorConstants.primaryBrownColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: ColorConstants.blackColor),
            onSelected: (value) {
              if (value == 'logout') {
                // Add logout logic here if needed
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Consumer<BookingsProvider>(
              builder: (context, provider, _) {
                if (provider.loading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ColorConstants.primaryBrownColor),
                    ),
                  );
                }
                if (provider.errorMessage.isNotEmpty) {
                  return Center(child: Text(provider.errorMessage));
                }
                if (provider.filteredBookings.isEmpty) {
                  return Center(
                      child: Text(_emptyMessageForFilter(provider.selectedFilter)));
                }
                return RefreshIndicator(
                  onRefresh: () => provider.loadBookings(),
                  color: ColorConstants.primaryBrownColor,
                  child: BookingList(
                    bookings: provider.filteredBookings,
                    onBookingTap: (Booking booking) => _showBookingDetails(context, booking),
                    onJoinMeetingTap: (Booking booking) => _launchMeetingLink(booking.link),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: ColorConstants.whiteColor,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: Icon(Icons.search, color: ColorConstants.hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstants.colorCCCCCC),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstants.colorCCCCCC),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstants.primaryBrownColor),
              ),
              filled: true,
              fillColor: ColorConstants.colorF9F9F9,
            ),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                'All',
                'Booked',
                'Confirmed',
                'Pending',
                'Completed',
                'Cancelled',
              ].map((filter) => Padding(
                padding: EdgeInsets.only(right: 8),
                child: FilterChipWidget(filter: filter),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyMessageForFilter(String selectedFilter) {
    switch (selectedFilter.toLowerCase()) {
      case 'all':
        return 'Your bookings will appear here when clients book sessions';
      case 'booked':
        return 'No booked sessions yet';
      case 'confirmed':
        return 'No confirmed bookings right now';
      case 'pending':
        return 'No pending bookings currently';
      case 'completed':
        return 'No completed sessions yet';
      case 'cancelled':
        return 'No cancelled bookings';
      default:
        return 'No bookings found for "$selectedFilter" status';
    }
  }
}

class FilterChipWidget extends StatelessWidget {
  final String filter;

  const FilterChipWidget({Key? key, required this.filter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingsProvider>();
    final isSelected = provider.selectedFilter == filter;

    return FilterChip(
      label: Text(filter),
      selected: isSelected,
      onSelected: (selected) {
        provider.setFilter(filter);
        provider.loadBookings();
      },
      selectedColor: ColorConstants.colorE6DBCF,
      checkmarkColor: ColorConstants.primaryBrownColor,
      labelStyle: TextStyle(
        color: isSelected ? ColorConstants.primaryBrownColor : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
