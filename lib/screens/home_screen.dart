import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:therapist_app/core/api_service.dart';
import 'package:therapist_app/core/authservices.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'All';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    print('Loading bookings...');

    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      print('User not logged in, cannot load bookings');
      setState(() {
        isLoading = false;
        errorMessage = 'Please login to view bookings';
      });
      return;
    }

    // Check if we have therapist ID
    final therapistId = await _authService.getTherapistId();
    print('Current therapist ID: $therapistId');
    
    if (therapistId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Therapist ID not found. Please login again.';
      });
      return;
    }

    await fetchBookingsData();
  }

  Future<void> fetchBookingsData() async {
    if (isRefreshing) {
      print('Already refreshing, skipping request');
      return;
    }

    setState(() {
      if (!isLoading) isRefreshing = true;
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Fetching bookings data...');
      
      // Get current therapist ID to verify
      final therapistId = await _authService.getTherapistId();
      print('Using therapist ID: $therapistId');
      
      if (therapistId == null) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          errorMessage = 'Therapist ID not found. Please login again.';
        });
        return;
      }

      final result = await _apiService.getBookings();

      print('Bookings API result: $result');

      if (result['success'] == true) {
        List<Map<String, dynamic>> fetchedBookings = [];

        // Handle the actual API response structure from your logs
        dynamic responseData = result['data'];
        
        if (responseData is Map<String, dynamic>) {
          // Extract the data array from the API response
          dynamic bookingsArray = responseData['data'];
          
          if (bookingsArray is List) {
            for (var booking in bookingsArray) {
              if (booking is Map<String, dynamic>) {
                // Parse customer information
                String clientName = 'Unknown Client';
                String clientId = '';
                
                if (booking['customerId'] is Map<String, dynamic>) {
                  final customer = booking['customerId'] as Map<String, dynamic>;
                  clientName = customer['fullName'] ?? 'Unknown Client';
                  clientId = customer['_id'] ?? '';
                }

                // Format date and time
                String formattedDate = 'No Date';
                String formattedTime = 'No Time';
                
                if (booking['meetDate'] != null) {
                  try {
                    final meetDate = DateTime.parse(booking['meetDate']);
                    formattedDate = '${meetDate.day}/${meetDate.month}/${meetDate.year}';
                  } catch (e) {
                    print('Date parsing error: $e');
                  }
                }
                
                if (booking['meetTime'] != null) {
                  formattedTime = booking['meetTime'];
                }

                fetchedBookings.add({
                  'id': booking['_id'] ?? '',
                  'clientName': clientName,
                  'clientId': clientId,
                  'date': formattedDate,
                  'time': formattedTime,
                  'price': '500', // Default price since it's not in the response
                  'type': booking['finished'] == true ? 'Completed' : 'Consultation',
                  'link': booking['meetLink'] ?? '',
                  'status': booking['meetStatus'] ?? 'Unknown',
                  'finished': booking['finished'] ?? false,
                  'meetingId': booking['_id'] ?? '',
                  'meetDate': booking['meetDate'],
                  'createdAt': booking['createdAt'],
                });
              }
            }
          }
        }

        print('Processed ${fetchedBookings.length} bookings');

        setState(() {
          bookings = fetchedBookings;
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        print('API returned error: ${result['error']}');
        setState(() {
          bookings = [];
          isLoading = false;
          isRefreshing = false;
          if (result['code'] == 401) {
            errorMessage = 'Session expired. Please login again.';
          } else {
            errorMessage = result['error'] ?? 'Failed to load bookings';
          }
        });
      }
    } catch (e) {
      print('Exception while fetching bookings: $e');
      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = 'Failed to load bookings: $e';
      });
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    try {
      final result = await _apiService.cancelBooking(booking['id']);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: ColorConstants.color2E7D7D,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        // Refresh the bookings list
        await fetchBookingsData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to cancel booking'),
              backgroundColor: ColorConstants.redColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking'),
            backgroundColor: ColorConstants.redColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> getFilteredBookings() {
    List<Map<String, dynamic>> filtered = bookings;

    if (selectedFilter != 'All') {
      filtered = filtered
          .where(
            (booking) =>
                booking['status'].toString().toLowerCase() ==
                selectedFilter.toLowerCase(),
          )
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (booking) =>
                booking['clientName'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                booking['type'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return ColorConstants.colorB2E5D1;
      case 'confirmed':
        return ColorConstants.blueColor.withOpacity(0.1);
      case 'pending':
        return ColorConstants.primaryOrangeColor.withOpacity(0.1);
      case 'cancelled':
        return ColorConstants.redColor.withOpacity(0.1);
      case 'completed':
        return ColorConstants.colorEFE5DA;
      default:
        return ColorConstants.grey3;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return ColorConstants.color2E7D7D;
      case 'confirmed':
        return ColorConstants.blueColor;
      case 'pending':
        return ColorConstants.primaryOrangeColor;
      case 'cancelled':
        return ColorConstants.redColor;
      case 'completed':
        return ColorConstants.primaryBrownColor;
      default:
        return ColorConstants.color999999;
    }
  }

  void _showBookingOptions(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorConstants.transparentColor,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorConstants.grey2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              booking['clientName'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryBrownColor,
              ),
            ),
            SizedBox(height: 20),
            _buildBottomSheetOption(
              Icons.info_outline,
              'View Details',
              ColorConstants.blueColor,
              () {
                Navigator.pop(context);
                _showBookingDetails(booking);
              },
            ),
            if (booking['link']?.toString().isNotEmpty == true)
              _buildBottomSheetOption(
                Icons.videocam,
                'Join Meeting',
                ColorConstants.color2E7D7D,
                () {
                  Navigator.pop(context);
                  _copyLink(booking['link']);
                },
              ),
            if (booking['status'].toString().toLowerCase() != 'cancelled' &&
                booking['status'].toString().toLowerCase() != 'completed')
              _buildBottomSheetOption(
                Icons.cancel_outlined,
                'Cancel Booking',
                ColorConstants.redColor,
                () {
                  Navigator.pop(context);
                  _confirmCancelBooking(booking);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Booking Details',
          style: TextStyle(color: ColorConstants.primaryBrownColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Client', booking['clientName']),
            _buildDetailRow('Date', booking['date']),
            _buildDetailRow('Time', booking['time']),
            _buildDetailRow('Price', '₹${booking['price']}'),
            _buildDetailRow('Type', booking['type']),
            _buildDetailRow('Status', booking['status']),
            if (booking['link']?.toString().isNotEmpty == true)
              _buildDetailRow('Meeting Link', booking['link'], isSelectable: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: ColorConstants.primaryBrownColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isSelectable = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ColorConstants.color999999,
              ),
            ),
          ),
          Expanded(
            child: isSelectable 
              ? SelectableText(
                  value,
                  style: TextStyle(color: ColorConstants.blackColor),
                )
              : Text(
                  value,
                  style: TextStyle(color: ColorConstants.blackColor),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meeting link copied to clipboard'),
          backgroundColor: ColorConstants.color2E7D7D,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _confirmCancelBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: TextStyle(color: ColorConstants.primaryBrownColor),
        ),
        content: Text(
          'Are you sure you want to cancel this booking with ${booking['clientName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: TextStyle(color: ColorConstants.color999999),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(booking);
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: ColorConstants.redColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      print('Logging out...');
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorConstants.primaryBrownColor,
                    ),
                  ),
                  SizedBox(width: 20),
                  Text("Logging out..."),
                ],
              ),
            ),
          );
        },
      );

      // Clear auth data
      await _authService.clearAuthData();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Navigate to auth screen and clear the entire navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (Route<dynamic> route) => false,
      );
      
    } catch (e) {
      print('Error during logout: $e');
      
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: ColorConstants.redColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = getFilteredBookings();

    return Scaffold(
      backgroundColor: ColorConstants.colorF5F5F5,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildBookingsList(filteredBookings)),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConstants.whiteColor,
      elevation: 0,
      title: Text(
        'My Bookings',
        style: TextStyle(
          color: ColorConstants.blackColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: ColorConstants.blackColor),
          onPressed: () => fetchBookingsData(),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: ColorConstants.blackColor),
          onSelected: (value) {
            if (value == 'logout') _logout();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: ColorConstants.whiteColor,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search clients or booking type...',
              prefixIcon: Icon(Icons.search, color: ColorConstants.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstants.grey2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstants.grey2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstants.primaryBrownColor),
              ),
              filled: true,
              fillColor: ColorConstants.grey3,
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All',
                'Booked',
                'Confirmed',
                'Pending',
                'Cancelled',
                'Completed',
              ].map((filter) => _buildFilterChip(filter)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    bool isSelected = selectedFilter == filter;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) => setState(() => selectedFilter = filter),
        selectedColor: ColorConstants.colorE6DBCF,
        checkmarkColor: ColorConstants.primaryBrownColor,
        labelStyle: TextStyle(
          color: isSelected
              ? ColorConstants.primaryBrownColor
              : ColorConstants.color999999,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> filteredBookings) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.primaryBrownColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your bookings...',
              style: TextStyle(color: ColorConstants.color999999, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    if (filteredBookings.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: fetchBookingsData,
      color: ColorConstants.primaryBrownColor,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) =>
            _buildBookingCard(filteredBookings[index]),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ColorConstants.redColor.withOpacity(0.7),
            ),
            SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryBrownColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ColorConstants.color999999),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: fetchBookingsData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBrownColor,
                    foregroundColor: ColorConstants.whiteColor,
                  ),
                  child: Text('Try Again'),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout',
                    style: TextStyle(color: ColorConstants.redColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: ColorConstants.color999999,
            ),
            SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryBrownColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              selectedFilter == 'All'
                  ? 'Your bookings will appear here when clients book sessions'
                  : 'No bookings found for "$selectedFilter" status',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ColorConstants.color999999),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchBookingsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryBrownColor,
                foregroundColor: ColorConstants.whiteColor,
              ),
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.colorBlack12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: ColorConstants.transparentColor,
        child: InkWell(
          onTap: () => _showBookingOptions(booking),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking['clientName'].toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryBrownColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(booking['status'].toString()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking['status'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: getStatusTextColor(
                            booking['status'].toString(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: ColorConstants.color999999,
                    ),
                    SizedBox(width: 8),
                    Text(
                      booking['date'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.color999999,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: ColorConstants.color999999,
                    ),
                    SizedBox(width: 8),
                    Text(
                      booking['time'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.color999999,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 16,
                      color: ColorConstants.color999999,
                    ),
                    SizedBox(width: 8),
                    Text(
                      booking['type'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.color999999,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '₹${booking['price']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.color2E7D7D,
                      ),
                    ),
                  ],
                ),
                if (booking['link']?.toString().isNotEmpty == true)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => _copyLink(booking['link']),
                      icon: Icon(
                        Icons.link,
                        size: 16,
                        color: ColorConstants.color2E7D7D,
                      ),
                      label: Text(
                        'Copy Meeting Link',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstants.color2E7D7D,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ColorConstants.color2E7D7D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}