import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:therapist_app/core/api_service.dart';
import 'package:therapist_app/core/authservices.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';

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
    print('=== LOADING BOOKINGS ===');

    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      print('User not logged in, cannot load bookings');
      setState(() {
        isLoading = false;
        errorMessage = 'Please login to view bookings';
      });
      return;
    }

    final therapistId = await _authService.getTherapistId();
    print('Current therapist ID: $therapistId');

    if (therapistId == null || therapistId.isEmpty) {
      print('Therapist ID not found, attempting to refresh user data...');
      await _authService.debugUserData();

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
      print('=== FETCHING BOOKINGS DATA ===');

      final therapistId = await _authService.getTherapistId();
      print('Using therapist ID: $therapistId');

      if (therapistId == null || therapistId.isEmpty) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          errorMessage = 'Therapist ID not found. Please login again.';
        });
        return;
      }

      // Always fetch ALL bookings once; apply UI filter locally to avoid backend status mismatch issues
      Map<String, dynamic> result = await _apiService.getBookings();

      print('=== BOOKINGS API RESULT ===');
      print('Success: ${result['success']}');
      print('Result keys: ${result.keys}');
      print('Full result: $result');

      if (result['success'] == true) {
        List<Map<String, dynamic>> fetchedBookings = [];

        dynamic responseData = result['data'];
        print('Response data type: ${responseData.runtimeType}');
        print('Response data: $responseData');

        // Handle the API response structure you mentioned
        if (responseData is Map<String, dynamic>) {
          // Check for the 'data' array in the response
          dynamic bookingsArray = responseData['data'];

          if (bookingsArray is List) {
            print(
              'Processing ${bookingsArray.length} raw bookings from responseData.data',
            );

            for (var booking in bookingsArray) {
              if (booking is Map<String, dynamic>) {
                try {
                  print('Processing booking: $booking');
                  fetchedBookings.add(_processBookingData(booking));
                } catch (e) {
                  print('Error processing booking: $e');
                  print('Problematic booking data: $booking');
                }
              }
            }
          } else {
            print(
              'No bookings array found in response.data. Available keys: ${responseData.keys}',
            );
            // Fallback: try other possible array locations
            dynamic fallbackArray =
                responseData['bookings'] ??
                responseData['results'] ??
                responseData;

            if (fallbackArray is List) {
              print(
                'Processing ${fallbackArray.length} raw bookings from fallback location',
              );
              for (var booking in fallbackArray) {
                if (booking is Map<String, dynamic>) {
                  fetchedBookings.add(_processBookingData(booking));
                }
              }
            }
          }
        } else if (responseData is List) {
          print(
            'Processing ${responseData.length} raw bookings from direct array',
          );
          for (var booking in responseData) {
            if (booking is Map<String, dynamic>) {
              fetchedBookings.add(_processBookingData(booking));
            }
          }
        }

        print('Successfully processed ${fetchedBookings.length} bookings');

        setState(() {
          bookings = fetchedBookings;
          isLoading = false;
          isRefreshing = false;
        });

        if (fetchedBookings.isNotEmpty) {
          print('Sample processed booking: ${fetchedBookings.first}');
        }
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

  Map<String, dynamic> _processBookingData(Map<String, dynamic> booking) {
    print('\n🔍 === PROCESSING BOOKING DATA ===');
    print('Raw booking keys: ${booking.keys.toList()}');
    print('Raw booking data: $booking');

    // Extract booking ID
    String bookingId =
        booking['_id']?.toString() ?? booking['id']?.toString() ?? '';
    print('📋 Booking ID: $bookingId');

    // Parse customer information with detailed debugging
    String clientName = 'Unknown Client';
    String clientId = '';
    String clientPhone = '';

    var customerData =
        booking['customerId'] ?? booking['customer'] ?? booking['client'];
    print('👤 Customer data: $customerData (${customerData.runtimeType})');

    if (customerData is Map<String, dynamic>) {
      print('👤 Customer is Map with keys: ${customerData.keys.toList()}');

      // Extract client name
      String? fullName = customerData['fullName']?.toString();
      String? name = customerData['name']?.toString();
      clientName = fullName ?? name ?? 'Unknown Client';
      print('👤 Client name extracted: $clientName');

      // Extract client ID
      String? customerId = customerData['_id']?.toString();
      String? id = customerData['id']?.toString();
      clientId = customerId ?? id ?? '';
      print('👤 Client ID extracted: $clientId');

      // Extract phone number
      String? phoneNumber = customerData['phoneNumber']?.toString();
      String? phone = customerData['phone']?.toString();
      String? mobile = customerData['mobile']?.toString();
      clientPhone = phoneNumber ?? phone ?? mobile ?? '';
      print('👤 Client phone extracted: $clientPhone');
    } else if (customerData is String) {
      clientId = customerData;
      clientName = 'Client $clientId';
      print('👤 Customer data is string: $customerData');
    } else {
      print(
        '❌ Customer data is neither Map nor String: ${customerData.runtimeType}',
      );
    }

    print('📅 Processing date and time...');
    String formattedDate = 'No Date';
    String formattedTime = 'No Time';
    String displayDate = 'No Date';
    DateTime? meetDateTime;

    String? meetDateStr = booking['meetDate']?.toString();
    print('📅 Raw meetDate: $meetDateStr');

    if (meetDateStr != null && meetDateStr.isNotEmpty) {
      try {
        meetDateTime = DateTime.parse(meetDateStr);
        formattedDate =
            '${meetDateTime.day.toString().padLeft(2, '0')}/${meetDateTime.month.toString().padLeft(2, '0')}/${meetDateTime.year}';

        // Create display date like "12 Aug 2025"
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        displayDate =
            '${meetDateTime.day} ${months[meetDateTime.month - 1]} ${meetDateTime.year}';

        print('📅 Parsed date successfully: $displayDate');
      } catch (e) {
        print('❌ Date parsing error for $meetDateStr: $e');
        formattedDate = meetDateStr;
        displayDate = meetDateStr;
      }
    }

    String? meetTimeStr = booking['meetTime']?.toString();
    print('🕐 Raw meetTime: $meetTimeStr');

    if (meetTimeStr != null && meetTimeStr.isNotEmpty) {
      formattedTime = meetTimeStr;
      print('🕐 Formatted time: $formattedTime');
    }

    // Extract meeting link with debugging
    String meetingLink =
        booking['meetLink']?.toString() ??
        booking['link']?.toString() ??
        booking['meetingLink']?.toString() ??
        '';
    print('🔗 Meeting link: $meetingLink');

    // Determine booking status and type
    // Normalize status consistently
    String rawStatus =
        booking['meetStatus']?.toString() ??
        booking['status']?.toString() ??
        'pending';
    String status = _normalizeStatus(rawStatus);
    bool isFinished = booking['finished'] ?? false;
    String type = isFinished ? 'Completed' : 'Video Meeting';
    print('📊 Status: $status, Finished: $isFinished, Type: $type');

    // Handle price/amount
    String price =
        booking['price']?.toString() ??
        booking['amount']?.toString() ??
        booking['fee']?.toString() ??
        booking['charge']?.toString() ??
        '500';
    print('💰 Price: $price');

    // Parse creation date
    DateTime? createdAt;
    String? createdAtStr = booking['createdAt']?.toString();
    print('📝 Raw createdAt: $createdAtStr');

    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        createdAt = DateTime.parse(createdAtStr);
        print('📝 Parsed createdAt: $createdAt');
      } catch (e) {
        print('❌ Error parsing createdAt: $e');
      }
    }

    final processedBooking = {
      'id': bookingId,
      'clientName': clientName,
      'clientId': clientId,
      'clientPhone': clientPhone,
      'date': formattedDate,
      'displayDate': displayDate,
      'time': formattedTime,
      'price': price,
      'type': type,
      'link': meetingLink,
      'status': status,
      'finished': isFinished,
      'meetingId': bookingId,
      'meetDate': booking['meetDate'],
      'meetDateTime': meetDateTime,
      'createdAt': createdAt,
      'notes': booking['notes']?.toString() ?? '',
      'duration': booking['duration']?.toString() ?? '60 mins',
      'rawData': booking, // Keep raw data for debugging
    };

    print('✅ Final processed booking:');
    print('   - ID: ${processedBooking['id']}');
    print('   - Client: ${processedBooking['clientName']}');
    print('   - Phone: ${processedBooking['clientPhone']}');
    print('   - Date: ${processedBooking['displayDate']}');
    print('   - Time: ${processedBooking['time']}');
    print('   - Link: ${processedBooking['link']}');
    print('   - Status: ${processedBooking['status']}');
    print('=== END PROCESSING ===\n');

    return processedBooking;
  }

  List<Map<String, dynamic>> getFilteredBookings() {
    List<Map<String, dynamic>> filtered = bookings;

    // Apply status filter locally (except 'All')
    final sel = selectedFilter.toLowerCase();
    if (sel != 'all') {
      filtered = filtered.where((b) {
        final st = (b['status'] ?? '').toString().toLowerCase();
        switch (sel) {
          case 'completed':
            return b['finished'] == true || st == 'completed';

          case 'booked':
            return st == 'booked';
          case 'rescheduled':
            return st == 'rescheduled';
          case 'cancelled':
            return st == 'cancelled';
          default:
            return true;
        }
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((booking) {
        return booking['clientName'].toString().toLowerCase().contains(q) ||
            booking['type'].toString().toLowerCase().contains(q) ||
            booking['status'].toString().toLowerCase().contains(q);
      }).toList();
    }

    // Sort by date - most recent first
    filtered.sort((a, b) {
      final dateA = a['meetDateTime'] as DateTime?;
      final dateB = b['meetDateTime'] as DateTime?;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  // Normalize backend variants to consistent UI statuses
  String _normalizeStatus(String status) {
    final s = status.toLowerCase().trim();

    if (s.contains('book')) return 'booked';
    if (s.contains('cancel')) return 'cancelled';
    if (s.contains('complete') || s.contains('finish')) return 'completed';
    if (s.contains('rescheduled') || s.isEmpty) return 'rescheduled';
    return s;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return Color(0xFFE8F5E8); // Light green
      case 'rescheduled':
        return Color(0xFFE3F2FD); // Light blue

      case 'cancelled':
        return Color(0xFFFFEBEE); // Light red
      case 'completed':
        return Color(0xFFEFE5DA); // Light brown
      default:
        return Colors.grey.shade100;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return Color(0xFF2E7D32); // Dark green
      case 'rescheduled':
        return Color.fromRGBO(25, 118, 210, 1); // Dark blue

      case 'cancelled':
        return Color(0xFFC62828); // Dark red
      case 'completed':
        return ColorConstants.primaryBrownColor;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _launchMeetingLink(String link) async {
    if (link.isEmpty) {
      _showMessage('Meeting link not available', isError: true);
      return;
    }
    try {
      String normalized = link.trim();
      // Ensure scheme
      if (!normalized.startsWith('http://') &&
          !normalized.startsWith('https://')) {
        normalized = 'https://$normalized';
      }

      final meetCodeRegex = RegExp(r'^[a-z]{3}-[a-z]{4}-[a-z]{3}$');
      if (meetCodeRegex.hasMatch(normalized)) {
        normalized = 'https://meet.google.com/$normalized';
      }

      if (normalized.startsWith('https://meet.google.com/') == false &&
          normalized.contains('-')) {
        final codeMatch = RegExp(
          r'([a-z]{3}-[a-z]{4}-[a-z]{3})',
        ).firstMatch(normalized);
        if (codeMatch != null) {
          normalized = 'https://meet.google.com/${codeMatch.group(1)}';
        }
      }

      Uri uri = Uri.parse(normalized);

      final isMeet = uri.host.contains('meet.google.com');

      if (isMeet && Platform.isAndroid) {
        try {
          final code =
              RegExp(
                r'([a-z]{3}-[a-z]{4}-[a-z]{3})',
              ).firstMatch(normalized)?.group(1) ??
              '';
          final meetIntent = AndroidIntent(
            action: 'action_view',
            data: normalized,
            package: 'com.google.android.apps.meetings',
            arguments: code.isNotEmpty ? {'CODE': code} : null,
          );
          await meetIntent.launch();
          return;
        } catch (e) {
          print('Explicit Meet intent failed: $e');
        }
      }

      // 2. Try external application (system chooser / associated app)
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }

      // 3. Fallback to in-app browser view (still not copying)
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
        if (launched) return;
      }

      _showMessage(
        'Cannot open meeting link. Please verify it.',
        isError: true,
      );
    } catch (e) {
      print('Error launching meeting link: $e');
      _showMessage('Failed to open meeting link', isError: true);
    }
  }

  // Clipboard copy removed as per requirement: always attempt to open link directly

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? ColorConstants.redColor
              : ColorConstants.color2E7D7D,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryBrownColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Client Info
              _buildDetailSection('Client Information', [
                _buildDetailRow('Name', booking['clientName']),
                if (booking['clientPhone'].toString().isNotEmpty)
                  _buildDetailRow('Phone', booking['clientPhone']),
                _buildDetailRow('Client ID', booking['clientId']),
              ]),

              SizedBox(height: 16),

              // Session Info
              _buildDetailSection('Session Details', [
                _buildDetailRow('Date', booking['displayDate']),
                _buildDetailRow('Time', booking['time']),
                _buildDetailRow('Type', booking['type']),
                _buildDetailRow('Duration', booking['duration']),
                _buildDetailRow('Fee', '₹${booking['price']}'),
                _buildDetailRow('Status', booking['status']),
                if (booking['createdAt'] != null)
                  _buildDetailRow(
                    'Booked On',
                    '${booking['createdAt'].day}/${booking['createdAt'].month}/${booking['createdAt'].year}',
                  ),
              ]),

              if (booking['notes'].toString().isNotEmpty) ...[
                SizedBox(height: 16),
                _buildDetailSection('Notes', [
                  Text(
                    booking['notes'],
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ]),
              ],

              if (booking['link']?.toString().isNotEmpty == true) ...[
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _launchMeetingLink(booking['link']);
                    },
                    icon: Icon(Icons.videocam, color: Colors.white),
                    label: Text(
                      'Join Meeting',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF6B35),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.primaryBrownColor,
          ),
        ),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    try {
      final result = await _apiService.cancelBooking(booking['id']);

      if (result['success'] == true) {
        if (mounted) {
          _showMessage('Booking cancelled successfully');
        }
        await fetchBookingsData();
      } else {
        if (mounted) {
          _showMessage(
            result['error'] ?? 'Failed to cancel booking',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to cancel booking', isError: true);
      }
    }
  }

  Future<void> _logout() async {
    try {
      print('Logging out...');

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

      await _authService.clearAuthData();

      Navigator.of(context).pop();

      if (mounted) {
        context.go('/auth');
      }
    } catch (e) {
      print('Error during logout: $e');

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        _showMessage('Error during logout. Please try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = getFilteredBookings();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'My Bookings',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.black),
          onPressed: () => fetchBookingsData(),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.black),
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
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstants.primaryBrownColor),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
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
                'Rescheduled',

                'Completed',
                'Cancelled',
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
        onSelected: (selected) {
          setState(() {
            selectedFilter = filter;
          });
          fetchBookingsData();
        },
        selectedColor: ColorConstants.colorE6DBCF,
        checkmarkColor: ColorConstants.primaryBrownColor,
        labelStyle: TextStyle(
          color: isSelected
              ? ColorConstants.primaryBrownColor
              : Colors.grey.shade600,
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) =>
            _buildModernBookingCard(filteredBookings[index]),
      ),
    );
  }

  Widget _buildModernBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
          onTap: () => _showBookingDetails(booking),
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
                        booking['clientName'].toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(booking['status'].toString()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking['status'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: getStatusTextColor(
                            booking['status'].toString(),
                          ),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                if (booking['clientPhone'].toString().isNotEmpty) ...[
                  Text(
                    booking['clientPhone'].toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 2),
                ],

                Text(
                  'Therapist Session',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                SizedBox(height: 16),

                // Date and Time Row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8),
                    Text(
                      booking['displayDate'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8),
                    Text(
                      booking['time'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '₹${booking['price']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.videocam, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Text(
                      booking['type'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (booking['link']?.toString().isNotEmpty == true) ...[
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchMeetingLink(booking['link']),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.link,
                            size: 16,
                            color: ColorConstants.primaryBrownColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking['link'],
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorConstants.primaryBrownColor,
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
                ],

                if (booking['link']?.toString().isNotEmpty == true) ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      // Reschedule Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Add reschedule functionality
                            _showMessage(
                              'Reschedule functionality coming soon',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.brown.shade600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.brown.shade600,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Reschedule',
                                style: TextStyle(
                                  color: Colors.brown.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Join Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _launchMeetingLink(booking['link']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF6B35), // Orange color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Join',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.link_off,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Meeting link will be provided soon',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: fetchBookingsData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBrownColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Try Again'),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red.shade600),
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
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
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
              _emptyMessageForFilter(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchBookingsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryBrownColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessageForFilter() {
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
      case 'rescheduled':
        return 'No rescheduled bookings';

      default:
        return 'No bookings found for "$selectedFilter" status';
    }
  }
}
