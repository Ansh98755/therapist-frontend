

import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Sample data - replace with actual user data
  final Map<String, dynamic> profileData = {
    'fullname': 'Dr. Sarah Johnson',
    'gender': 'Female',
    'phoneNumber': '+91 9876543210',
    'pictureUrl': 'https://via.placeholder.com/150',
    'meetLink': 'https://meet.google.com/dr-sarah-johnson',
    'experience': 8,
    'expertise': ['Cardiology', 'Internal Medicine', 'Preventive Care'],
    'languages': ['English', 'Hindi', 'Spanish'],
    'qualifications': ['MBBS', 'MD Cardiology', 'Fellowship in Interventional Cardiology'],
    'charge': 1500,
    'companyCut': 300,
    'priority': 1,
    'isActive': true,
    'message': 'Dedicated to providing comprehensive cardiac care with a patient-centered approach. I believe in treating each patient with personalized attention and evidence-based medicine.',
    'joinedAt': '15 Jan 2020',
    'availability': {
      'Monday': ['09:00-13:00', '15:00-18:00'],
      'Tuesday': ['09:00-13:00', '15:00-18:00'],
      'Wednesday': ['09:00-13:00'],
      'Thursday': ['09:00-13:00', '15:00-18:00'],
      'Friday': ['09:00-13:00', '15:00-18:00'],
      'Saturday': ['10:00-14:00'],
      'Sunday': ['Unavailable']
    }
  };

  @override
  Widget build(BuildContext context) {
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
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.brown.shade600,
                      Colors.brown.shade700,
                    ],
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
                            backgroundImage: profileData['pictureUrl'] != null
                                ? NetworkImage(profileData['pictureUrl'])
                                : null,
                            child: profileData['pictureUrl'] == null
                                ? Icon(Icons.person, size: 70, color: Colors.brown.shade400)
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
                              color: profileData['isActive'] ? Colors.green.shade500 : Colors.red.shade500,
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
                              profileData['isActive'] ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      profileData['fullname'],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profileData['isActive'] ? 'Active • ${profileData['experience']} Years Experience' : 'Inactive',
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

          // Content
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
                          '₹${profileData['charge']}',
                          'Consultation Fee',
                          Icons.currency_rupee,
                          Colors.green.shade500,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Level ${profileData['priority']}',
                          'Priority',
                          Icons.star,
                          Colors.orange.shade500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Contact Information
                  _buildInfoCard(
                    'Contact Information',
                    Icons.contacts,
                    [
                      _buildInfoRow(Icons.phone_rounded, 'Phone Number', profileData['phoneNumber']),
                      _buildInfoRow(Icons.person_rounded, 'Gender', profileData['gender']),
                      _buildInfoRow(Icons.link_rounded, 'Meet Link', profileData['meetLink'], isLink: true),
                      _buildInfoRow(Icons.calendar_today_rounded, 'Member Since', profileData['joinedAt']),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Skills Section (Expertise, Languages, Qualifications)
                  _buildSkillsSection(),

                  SizedBox(height: 20),

                  // About Section
                  if (profileData['message'] != null && profileData['message'].isNotEmpty)
                    _buildAboutCard(),

                  SizedBox(height: 20),

                  // Availability Section
                  _buildAvailabilityCard(),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
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

  Widget _buildInfoCard(String title, IconData titleIcon, List<Widget> children) {
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

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLink = false}) {
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
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLink ? Colors.blue.shade600 : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      children: [
        _buildChipCard('Expertise', profileData['expertise'], Colors.blue.shade500),
        SizedBox(height: 16),
        _buildChipCard('Languages', profileData['languages'], Colors.purple.shade500),
        SizedBox(height: 16),
        _buildChipCard('Qualifications', profileData['qualifications'], Colors.green.shade500),
      ],
    );
  }

  Widget _buildChipCard(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 140), // Consistent minimum height
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForTitle(title),
                  color: color,
                  size: 22,
                ),
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
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: items.map((item) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Expertise':
        return Icons.medical_services_rounded;
      case 'Languages':
        return Icons.language_rounded;
      case 'Qualifications':
        return Icons.school_rounded;
      default:
        return Icons.info_rounded;
    }
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
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_rounded, color: Colors.orange.shade600, size: 22),
              ),
              SizedBox(width: 12),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            profileData['message'],
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
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
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.schedule_rounded, color: Colors.teal.shade600, size: 22),
              ),
              SizedBox(width: 12),
              Text(
                'Availability',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...profileData['availability'].entries.map((entry) {
            String day = entry.key;
            List<String> times = List<String>.from(entry.value);
            bool isUnavailable = times.contains('Unavailable');
            
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnavailable ? Colors.red.shade50 : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnavailable ? Colors.red.shade200 : Colors.teal.shade200,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: isUnavailable
                        ? Text(
                            'Unavailable',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: times.map((time) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )).toList(),
                          ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}