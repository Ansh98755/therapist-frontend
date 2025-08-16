import 'package:flutter/material.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'All';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> bookings = [
    {
      'name': 'Nayonika Bisnwas',
      'profession': 'Therapist',
      'date': '12 Aug 2025',
      'time': '12:00',
      'price': '₹1012',
      'type': 'Video Meeting',
      'link': 'https://meet.google.com/pbf-gsmg-oat',
      'status': 'Booked'
    },
    {
      'name': 'Dr. Rajesh Sharma',
      'profession': 'Cardiologist',
      'date': '15 Aug 2025',
      'time': '14:30',
      'price': '₹850',
      'type': 'In-person',
      'link': 'Clinic Address: 123 Health Street',
      'status': 'Confirmed'
    },
    {
      'name': 'Sarah Johnson',
      'profession': 'Physiotherapist',
      'date': '18 Aug 2025',
      'time': '10:15',
      'price': '₹650',
      'type': 'Video Meeting',
      'link': 'https://meet.google.com/xyz-abcd-123',
      'status': 'Pending'
    },
    {
      'name': 'Dr. Priya Mehta',
      'profession': 'Dermatologist',
      'date': '20 Aug 2025',
      'time': '16:45',
      'price': '₹1200',
      'type': 'In-person',
      'link': 'Clinic Address: 456 Skin Care Plaza',
      'status': 'Booked'
    },
    {
      'name': 'Michael Brown',
      'profession': 'Nutritionist',
      'date': '22 Aug 2025',
      'time': '11:00',
      'price': '₹500',
      'type': 'Video Meeting',
      'link': 'https://meet.google.com/nutrition-call',
      'status': 'Cancelled'
    },
    {
      'name': 'Dr. Anita Kumar',
      'profession': 'Psychiatrist',
      'date': '25 Aug 2025',
      'time': '13:20',
      'price': '₹1500',
      'type': 'Video Meeting',
      'link': 'https://meet.google.com/mental-health',
      'status': 'Confirmed'
    },
    {
      'name': 'James Wilson',
      'profession': 'Fitness Trainer',
      'date': '28 Aug 2025',
      'time': '07:00',
      'price': '₹800',
      'type': 'In-person',
      'link': 'Gym Address: 789 Fitness Center',
      'status': 'Booked'
    },
    {
      'name': 'Dr. Kavita Singh',
      'profession': 'Pediatrician',
      'date': '30 Aug 2025',
      'time': '15:30',
      'price': '₹750',
      'type': 'Video Meeting',
      'link': 'https://meet.google.com/child-care',
      'status': 'Pending'
    },
    {
      'name': 'Lisa Anderson',
      'profession': 'Yoga Instructor',
      'date': '02 Sep 2025',
      'time': '06:30',
      'price': '₹400',
      'type': 'In-person',
      'link': 'Studio Address: 321 Wellness Center',
      'status': 'Confirmed'
    },
    {
      'name': 'Dr. Amit Patel',
      'profession': 'Orthopedic',
      'date': '05 Sep 2025',
      'time': '17:15',
      'price': '₹1100',
      'type': 'Video Meeting',
      'link': 'https://meet.google.com/bone-health',
      'status': 'Booked'
    }
  ];

  List<Map<String, dynamic>> getFilteredBookings() {
    List<Map<String, dynamic>> filtered = bookings;
    
    if (selectedFilter != 'All') {
      filtered = filtered.where((booking) => booking['status'] == selectedFilter).toList();
    }
    
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) => 
        booking['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
        booking['profession'].toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Booked':
        return Colors.green.shade100;
      case 'Confirmed':
        return Colors.blue.shade100;
      case 'Pending':
        return Colors.orange.shade100;
      case 'Cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status) {
      case 'Booked':
        return Colors.green.shade700;
      case 'Confirmed':
        return Colors.blue.shade700;
      case 'Pending':
        return Colors.orange.shade700;
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredBookings = getFilteredBookings();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: ColorConstants.boxShadowOrangeOpacity,
        elevation: 0,
        
        title: Text(
          'My Bookings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bookings...',
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
                      borderSide: BorderSide(color: Colors.brown.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Booked', 'Confirmed', 'Pending', 'Cancelled'].map((filter) {
                      bool isSelected = selectedFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                          selectedColor: Colors.brown.shade100,
                          checkmarkColor: Colors.brown.shade700,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.brown.shade700 : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredBookings.length,
              itemBuilder: (context, index) {
                final booking = filteredBookings[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  booking['profession'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: getStatusColor(booking['status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  booking['status'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: getStatusTextColor(booking['status']),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.more_vert, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          SizedBox(width: 8),
                          Text(
                            booking['date'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                          SizedBox(width: 8),
                          Text(
                            booking['time'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.currency_rupee, size: 16, color: Colors.grey.shade600),
                          Text(
                            booking['price'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            booking['type'] == 'Video Meeting' ? Icons.videocam : Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 8),
                          Text(
                            booking['type'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.link, size: 16, color: Colors.blue.shade400),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking['link'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy, size: 14, color: Colors.grey.shade700),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.brown.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Reschedule',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam, color: Colors.white, size: 18),
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
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
