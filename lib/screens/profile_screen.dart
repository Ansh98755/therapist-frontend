import 'package:flutter/material.dart';
import 'package:therapist_app/core/api_service.dart';
import 'package:therapist_app/core/authservices.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

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
      print('Loading profile data...');

      // Try to get therapist profile using getTherapistById
      final result = await _apiService.getTherapistById();
      
      print('Profile API result: $result');

      if (result['success'] == true) {
        setState(() {
          profileData = result['data'];
          isLoading = false;
        });
      } else {
        // If that fails, try getUserProfile as fallback
        final fallbackResult = await _apiService.getUserProfile();
        print('Fallback profile result: $fallbackResult');
        
        if (fallbackResult['success'] == true) {
          setState(() {
            profileData = fallbackResult['data'];
            isLoading = false;
          });
        } else {
          // As last resort, use cached user data from auth service
          final cachedData = await _authService.getUserData();
          if (cachedData != null) {
            setState(() {
              profileData = cachedData;
              isLoading = false;
            });
          } else {
            setState(() {
              errorMessage = result['error'] ?? 'Failed to load profile data';
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        errorMessage = 'Failed to load profile data: $e';
        isLoading = false;
      });
    }
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

  String _getFieldValue(String key, [String defaultValue = 'Not Available']) {
    if (profileData == null) return defaultValue;
    
    // Try different possible field names
    final possibleKeys = [
      key,
      key.toLowerCase(),
      key.toUpperCase(),
      '${key.toLowerCase()}_name',
      '${key}Name',
    ];
    
    for (String possibleKey in possibleKeys) {
      if (profileData!.containsKey(possibleKey) && 
          profileData![possibleKey] != null && 
          profileData![possibleKey].toString().isNotEmpty) {
        return profileData![possibleKey].toString();
      }
    }
    
    return defaultValue;
  }

  List<String> _getListField(String key) {
    if (profileData == null) return [];
    
    final value = profileData![key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else if (value is String && value.isNotEmpty) {
      // Handle comma-separated string
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  bool _getBoolField(String key, [bool defaultValue = false]) {
    if (profileData == null) return defaultValue;
    
    final value = profileData![key];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value > 0;
    
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final scale = width / 375.0;
    
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
                style: TextStyle(
                  color: ColorConstants.color999999,
                  fontSize: 16,
                ),
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
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorConstants.color999999,
                  ),
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
            expandedHeight: 280 * scale,
            floating: false,
            pinned: true,
            backgroundColor: Colors.brown.shade600,
            actions: [
              Container(
                margin: EdgeInsets.only(
                  right: 16 * scale,
                  top: 8 * scale,
                  bottom: 8 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 22 * scale),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Edit functionality coming soon!'),
                        backgroundColor: Colors.brown.shade600,
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  right: 16 * scale,
                  top: 8 * scale,
                  bottom: 8 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.white, size: 22 * scale),
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
                    SizedBox(height: 60 * scale),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4 * scale,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15 * scale,
                                offset: Offset(0, 8 * scale),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 65 * scale,
                            backgroundColor: Colors.white,
                            backgroundImage: _getFieldValue('profile_picture') != 'Not Available' &&
                                    _getFieldValue('pictureUrl') != 'Not Available'
                                ? NetworkImage(_getFieldValue('profile_picture') != 'Not Available' 
                                    ? _getFieldValue('profile_picture') 
                                    : _getFieldValue('pictureUrl'))
                                : null,
                            child: (_getFieldValue('profile_picture') == 'Not Available' &&
                                    _getFieldValue('pictureUrl') == 'Not Available')
                                ? Icon(
                                    Icons.person,
                                    size: 70 * scale,
                                    color: Colors.brown.shade400,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 8 * scale,
                          right: 8 * scale,
                          child: Container(
                            width: 28 * scale,
                            height: 28 * scale,
                            decoration: BoxDecoration(
                              color: _getBoolField('isActive', true)
                                  ? Colors.green.shade500
                                  : Colors.red.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3 * scale,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4 * scale,
                                  offset: Offset(0, 2 * scale),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getBoolField('isActive', true)
                                  ? Icons.check
                                  : Icons.close,
                              color: Colors.white,
                              size: 16 * scale,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20 * scale),
                    Text(
                      _getFieldValue('fullName', 'Therapist Name'),
                      style: TextStyle(
                        fontSize: 28 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 8 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                      child: Text(
                        _getBoolField('isActive', true)
                            ? 'Active  ${_getFieldValue('experience', '0')} Years Experience'
                            : 'Inactive',
                        style: TextStyle(
                          fontSize: 16 * scale,
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

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20 * scale),
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
                          'Level ${_getFieldValue('priority', '1')}',
                          'Priority',
                          Icons.star,
                          Colors.orange.shade500,
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
                    _buildInfoRow(
                      Icons.calendar_today_rounded,
                      'Member Since',
                      _getFieldValue('joinedAt', _getFieldValue('createdAt', 'Unknown')),
                    ),
                  ]),

                  SizedBox(height: 20),

                  // Skills Section (if available)
                  if (_getListField('expertise').isNotEmpty ||
                      _getListField('languages').isNotEmpty ||
                      _getListField('qualifications').isNotEmpty)
                    _buildSkillsSection(),

                  if (_getListField('expertise').isNotEmpty ||
                      _getListField('languages').isNotEmpty ||
                      _getListField('qualifications').isNotEmpty)
                    SizedBox(height: 20),

                  // About Section
                  if (_getFieldValue('message') != 'Not Available' &&
                      _getFieldValue('message').isNotEmpty)
                    _buildAboutCard(),

                  if (_getFieldValue('message') != 'Not Available' &&
                      _getFieldValue('message').isNotEmpty)
                    SizedBox(height: 20),

                  // Debug Info Card (for development)
                  if (profileData != null)
                    _buildDebugCard(),

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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.brown.shade600),
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
                isLink
                    ? GestureDetector(
                        onTap: () {
                          // Handle link tap
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
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
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

  Widget _buildSkillsSection() {
    final expertise = _getListField('expertise');
    final languages = _getListField('languages');
    final qualifications = _getListField('qualifications');

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
                child: Icon(Icons.psychology, color: Colors.brown.shade600, size: 22),
              ),
              SizedBox(width: 12),
              Text(
                'Skills & Qualifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          if (expertise.isNotEmpty) _buildSkillChips('Expertise', expertise),
          if (languages.isNotEmpty) _buildSkillChips('Languages', languages),
          if (qualifications.isNotEmpty) _buildSkillChips('Qualifications', qualifications),
        ],
      ),
    );
  }

  Widget _buildSkillChips(String title, List<String> skills) {
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
                  color: Colors.brown.shade700,
                ),
              ),
              backgroundColor: Colors.brown.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.brown.shade200),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAboutCard() {
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
          Text(
            _getFieldValue('message'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Profile Data Keys: ${profileData!.keys.join(', ')}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}