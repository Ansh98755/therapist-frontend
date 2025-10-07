import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:therapist_app/api_services/api_service.dart';
import 'package:therapist_app/core/shared_pref.dart';
import 'package:therapist_app/screens/profile_screen/profile_edit.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

import '../../api_services/auth_services.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('=== LOADING PROFILE DATA ===');

      // Debug current auth state
      await _authService.debugUserData();

      // Get therapist profile using getTherapistById
      final result = await _apiService.getTherapistById();

      print('=== API RESULT ===');
      print('Success: ${result['success']}');
      print('Result keys: ${result.keys}');
      print('Full result: $result');

      if (result['success'] == true && result['data'] != null) {
        final responseData = result['data'];
        print('Response data type: ${responseData.runtimeType}');
        print('Response data: $responseData');

        Map<String, dynamic> extractedData = {};

        if (responseData is Map<String, dynamic>) {
          extractedData = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception('Unexpected data format');
        }

        final processedData = _processProfileData(extractedData);
        print('${processedData['fullname']}');
        await SharedPrefService().saveFullName(processedData['fullname'] ?? '');
        setState(() {
          profileData = processedData;
          isLoading = false;
        });

        print('=== FINAL PROFILE DATA ===');
        print('Profile data keys: ${profileData!.keys}');
        profileData!.forEach((key, value) {
          print('$key: $value (${value.runtimeType})');
        });

        return; // Success, exit method
      }

      print('Primary method failed, trying fallback methods...');

      // Fallback: Use cached user data from auth service
      final cachedData = await _authService.getUserData();
      print('Cached user data: $cachedData');

      if (cachedData != null) {
        final processedData = _processProfileData(cachedData);
        setState(() {
          profileData = processedData;
          isLoading = false;
        });
        return;
      }

      // All methods failed
      setState(() {
        errorMessage = result['error'] ?? 'Failed to load profile data';
        isLoading = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        errorMessage = 'Failed to load profile data: $e';
        isLoading = false;
      });
    }
  }

  // Process data to match the actual API response format
  Map<String, dynamic> _processProfileData(Map<String, dynamic> rawData) {
    print('=== PROCESSING PROFILE DATA ===');
    print('Raw data keys: ${rawData.keys}');

    Map<String, dynamic> processed = {};

    // Map API response fields correctly based on actual API structure
    processed['id'] = rawData['id'] ?? rawData['_id'];
    processed['fullName'] = rawData['fullname'] ?? ''; // API uses 'fullname'
    processed['profilePicture'] =
        rawData['pictureUrl'] ?? ''; // API uses 'pictureUrl'
    processed['experience'] = rawData['experience']?.toString() ?? '';
    processed['expertise'] = rawData['expertise'] is List
        ? rawData['expertise']
        : [];
    processed['languages'] = rawData['languages'] is List
        ? rawData['languages']
        : [];
    processed['charge'] = rawData['charge']?.toString() ?? '';
    processed['phoneNumber'] = rawData['phoneNumber'] ?? '';
    processed['meetLink'] = rawData['meetLink'] ?? '';
    processed['message'] = rawData['message'] ?? '';

    // Fields that may not exist in current API response
    processed['gender'] = rawData['gender'] ?? '';
    processed['qualifications'] = rawData['qualifications'] ?? '';
    processed['availability'] = rawData['availability'] ?? '';
    processed['isActive'] = rawData['isActive'] ?? rawData['active'] ?? true;

    print('Processed data keys: ${processed.keys}');
    return processed;
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

  // Enhanced field value extraction with proper field mapping
  String _getFieldValue(String key, [String defaultValue = 'Not Available']) {
    if (profileData == null) return defaultValue;

    final value = profileData![key];
    if (value != null &&
        value.toString().isNotEmpty &&
        value.toString() != 'null') {
      return value.toString();
    }

    return defaultValue;
  }

  List<String> _getListField(String key) {
    if (profileData == null) return [];

    final value = profileData![key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else if (value is String && value.isNotEmpty && value != 'null') {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  bool _getBoolField(String key, [bool defaultValue = false]) {
    if (profileData == null) return defaultValue;

    final value = profileData![key];
    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      return lowerValue == 'true' ||
          lowerValue == '1' ||
          lowerValue == 'active' ||
          lowerValue == 'yes';
    }
    if (value is num) return value > 0;

    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
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
                'Loading profile...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.brown.shade600,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: Icon(Icons.logout), onPressed: _logout)],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                SizedBox(height: 16),
                Text(
                  'Failed to load profile',
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
                ElevatedButton(
                  onPressed: _loadProfileData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBrownColor,
                    foregroundColor: ColorConstants.whiteColor,
                  ),
                  child: Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Colors.brown.shade600,
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 22),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileEditScreen(initialData: profileData),
                      ),
                    );

                    // Refresh profile data if edit was successful
                    if (result == true) {
                      _loadProfileData();
                    }
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.white, size: 22),
                  onPressed: _logout,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.brown.shade600, Colors.brown.shade700],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                _getFieldValue('profilePicture').isNotEmpty &&
                                    _getFieldValue('profilePicture') !=
                                        'Not Available'
                                ? NetworkImage(_getFieldValue('profilePicture'))
                                : null,
                            child:
                                _getFieldValue('profilePicture') ==
                                    'Not Available'
                                ? Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Colors.brown.shade400,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _getBoolField('isActive', true)
                                  ? Colors.green.shade500
                                  : Colors.red.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getBoolField('isActive', true)
                                  ? Icons.check
                                  : Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      _getFieldValue('fullName', 'Therapist Name'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getBoolField('isActive', true)
                            ? 'Active • ${_getFieldValue('experience', '0')} Years Experience'
                            : 'Inactive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Quick Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '₹${_getFieldValue('charge', '0')}',
                          'Consultation Fee',
                          Icons.currency_rupee,
                          Colors.green.shade500,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '${_getFieldValue('experience', '0')} Years',
                          'Experience',
                          Icons.timeline,
                          Colors.blue.shade500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Contact Information
                  _buildInfoCard('Contact Information', Icons.contacts, [
                    _buildInfoRow(
                      Icons.phone_rounded,
                      'Phone Number',
                      _getFieldValue('phoneNumber', 'Not Available'),
                    ),
                    _buildInfoRow(
                      Icons.person_rounded,
                      'Gender',
                      _getFieldValue('gender', 'Not Specified'),
                    ),
                    if (_getFieldValue('meetLink') != 'Not Available')
                      _buildInfoRow(
                        Icons.link_rounded,
                        'Meet Link',
                        _getFieldValue('meetLink'),
                        isLink: true,
                      ),
                  ]),

                  SizedBox(height: 20),

                  // Professional Information
                  _buildInfoCard('Professional Information', Icons.work, [
                    if (_getFieldValue('experience') != 'Not Available')
                      _buildInfoRow(
                        Icons.timeline,
                        'Experience',
                        '${_getFieldValue('experience')} years',
                      ),
                    if (_getFieldValue('charge') != 'Not Available')
                      _buildInfoRow(
                        Icons.currency_rupee,
                        'Consultation Fee',
                        '₹${_getFieldValue('charge')}',
                      ),
                    if (_getFieldValue('availability') != 'Not Available')
                      _buildInfoRowWidget(
                        Icons.schedule,
                        'Availability',
                        buildAvailabilitySlots(_getFieldValue('availability')),
                      )
                    else
                      _buildInfoRowWidget(
                        Icons.schedule,
                        'Availability',
                        Text(
                          'Please set your availability',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ),

                    if (_getFieldValue('qualifications') != 'Not Available')
                      _buildInfoRowWidget(
                        Icons.school,
                        'Qualifications',
                        buildQualificationsChips(
                          _getFieldValue('qualifications'),
                        ),
                      )
                    else
                      _buildInfoRow(
                        Icons.school,
                        'Qualification',
                        'Please specify your qualification',
                        isEmpty: true,
                      ),
                  ]),

                  SizedBox(height: 20),

                  // Skills Section
                  _buildSkillsSection(),

                  SizedBox(height: 20),

                  // About Section
                  _buildAboutCard(),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
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
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData titleIcon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(titleIcon, color: Colors.brown.shade600, size: 22),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget buildAvailabilitySlots(dynamic availabilityData) {
    Map<String, List<String>> availability = {};

    try {
      if (availabilityData is Map<String, dynamic>) {
        // Already in map form
        availability = availabilityData.map((key, value) {
          final times = List<String>.from(value);
          return MapEntry(key, times);
        });
      } else if (availabilityData is String) {
        String data = availabilityData.trim();

        // Example format: {Tuesday: [11:00, 12:00], Wednesday: [11:00]}
        // Remove outer braces
        if (data.startsWith('{') && data.endsWith('}')) {
          data = data.substring(1, data.length - 1); // remove {}

          // Split by commas not inside brackets
          final entries = data.split(RegExp(r',(?![^\[]*\])'));

          for (var entry in entries) {
            final parts = entry.split(':');
            if (parts.length >= 2) {
              final day = parts[0].trim();
              String timesPart = parts.sublist(1).join(':').trim();

              // Remove brackets []
              if (timesPart.startsWith('[') && timesPart.endsWith(']')) {
                timesPart = timesPart.substring(1, timesPart.length - 1);
              }

              // Split times
              final times = timesPart.split(',').map((t) => t.trim()).toList();

              availability[day] = times;
            }
          }
        }
      }
    } catch (e) {
      print("Error parsing availability: $e");
      return Text('Invalid availability data');
    }

    if (availability.isEmpty) {
      return Text('No availability set');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availability.entries.map((entry) {
        final day = entry.key;
        final times = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: times.map((time) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(time, style: TextStyle(fontSize: 14)),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    bool isEmpty = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEmpty ? Colors.orange.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isEmpty ? Colors.orange.shade600 : Colors.brown.shade600,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                isLink && value != 'Not Available' && !isEmpty
                    ? GestureDetector(
                        onTap: () {
                          // Handle link tap - could launch URL or copy to clipboard
                        },
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          color: isEmpty
                              ? Colors.orange.shade600
                              : value == 'Not Available'
                              ? Colors.grey.shade500
                              : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontStyle: (value == 'Not Available' || isEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWidget(
    IconData icon,
    String label,
    Widget valueWidget, {
    bool isEmpty = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEmpty ? Colors.orange.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isEmpty ? Colors.orange.shade600 : Colors.brown.shade600,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                valueWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQualificationsChips(dynamic qualificationsData) {
    List<String> qualifications = [];

    try {
      List<dynamic> parsedData = [];

      if (qualificationsData is String) {
        String data = qualificationsData.trim();

        // Handle different patterns: [["id", "kl"]], [["id"]], ["id"]
        if (data.startsWith('[[') && data.endsWith(']]')) {
          data = data.substring(2, data.length - 2); // remove outer brackets
          parsedData = data.split(',').map((e) => e.trim()).toList();
        } else if (data.startsWith('[') && data.endsWith(']')) {
          data = data.substring(1, data.length - 1);
          parsedData = data.split(',').map((e) => e.trim()).toList();
        }
      } else if (qualificationsData is List) {
        parsedData = qualificationsData;
      }

      // Map parsedData to strings
      qualifications = parsedData.map((item) {
        if (item is List && item.isNotEmpty) {
          return item[1 >= item.length ? 0 : 1]
              .toString(); // fallback to first if second not present
        } else if (item is String) {
          return item;
        } else {
          return item.toString();
        }
      }).toList();
    } catch (e) {
      print("Error parsing qualifications: $e");
      qualifications = ['Invalid data format'];
    }

    if (qualifications.isEmpty) {
      qualifications.add('No qualifications available');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: qualifications.map((q) {
        return Chip(
          label: Text(q, style: TextStyle(fontSize: 14, color: Colors.black87)),
        );
      }).toList(),
    );
  }

  Widget _buildSkillsSection() {
    final expertise = _getListField('expertise');
    final languages = _getListField('languages');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Colors.brown.shade600,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Skills & Languages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          if (expertise.isNotEmpty)
            _buildSkillChips('Expertise', expertise, Colors.blue),
          if (languages.isNotEmpty)
            _buildSkillChips('Languages', languages, Colors.green),

          if (expertise.isEmpty && languages.isEmpty)
            Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 12),
                Text(
                  'No skills added yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap edit to add your expertise and languages',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSkillChips(
    String title,
    List<String> skills,
    MaterialColor color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return Chip(
              label: Text(
                skill,
                style: TextStyle(
                  fontSize: 14,
                  color: color.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: color.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: color.shade200),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAboutCard() {
    final message = _getFieldValue('message');
    final hasMessage = message != 'Not Available' && message.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info, color: Colors.brown.shade600, size: 22),
              ),
              SizedBox(width: 12),
              Text(
                'About Me',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          hasMessage
              ? Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                )
              : Column(
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No about message added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap edit to add a professional message about yourself',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
