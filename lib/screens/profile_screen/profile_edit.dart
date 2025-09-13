import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:therapist_app/api_services/api_service.dart';
import 'package:therapist_app/utils/color_constants/availability_constants.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';
import 'dart:io';
import 'dart:convert';

import '../../api_services/auth_services.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ProfileEditScreen({Key? key, this.initialData}) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final _fullNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _meetLinkController = TextEditingController();
  final _experienceController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _languagesController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _chargeController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentProfilePicture;

  // Availability data - now stores selected time slots for each day
  final Map<String, Set<String>> _availability = AvailabilityConstants.weekDays;

  // Available time slots based on day type
  final Map<String, List<String>> _timeSlotsByDay =
      AvailabilityConstants.timeSlotsByDay;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      print("data  $data");
      // Get the raw qualifications
      dynamic qualificationsData = data['qualifications'];
      print("Raw qualifications data: $qualificationsData");
      print("Type of qualificationsData: ${qualificationsData.runtimeType}");

      // Flatten and set the controller once
      _qualificationsController.text = _parseNestedListField(
        qualificationsData,
      );
      print(
        "Data of qualification after flattening: ${_qualificationsController.text}",
      );

      _fullNameController.text = _getFieldValue(data, 'fullName', 'fullname');
      _genderController.text = _getFieldValue(data, 'gender');
      _meetLinkController.text = _getFieldValue(data, 'meetLink');
      _experienceController.text = _getFieldValue(data, 'experience');

      _expertiseController.text = _formatListField(data, 'expertise');
      _languagesController.text = _formatListField(data, 'languages');

      _chargeController.text = _getFieldValue(data, 'charge');
      _messageController.text = _getFieldValue(data, 'message');

      _parseAvailabilityFromBackend(data);

      _currentProfilePicture = _getFieldValue(
        data,
        'profilePicture',
        'pictureUrl',
      );
      if (_currentProfilePicture == 'Not Available' ||
          _currentProfilePicture == 'null') {
        _currentProfilePicture = null;
      }
    }
  }

  void _parseAvailabilityFromBackend(Map<String, dynamic> data) {
    if (data['availability'] != null && data['availability'] is Map) {
      final availabilityData = data['availability'] as Map<String, dynamic>;

      availabilityData.forEach((day, slots) {
        if (_availability.containsKey(day) && slots is List) {
          _availability[day] = Set<String>.from(slots);
        }
      });
    }
  }

  Map<String, List<String>> _generateBackendAvailability() {
    Map<String, List<String>> backendAvailability = {};

    _availability.forEach((day, slots) {
      if (slots.isNotEmpty) {
        backendAvailability[day] = slots.toList()..sort();
      }
    });

    return backendAvailability;
  }

  String _getFieldValue(
    Map<String, dynamic> data,
    String key, [
    String? alternativeKey,
  ]) {
    if (data.containsKey(key) &&
        data[key] != null &&
        data[key].toString().isNotEmpty &&
        data[key].toString() != 'Not Available' &&
        data[key].toString() != 'null') {
      return data[key].toString();
    }

    if (alternativeKey != null &&
        data.containsKey(alternativeKey) &&
        data[alternativeKey] != null &&
        data[alternativeKey].toString().isNotEmpty &&
        data[alternativeKey].toString() != 'Not Available' &&
        data[alternativeKey].toString() != 'null') {
      return data[alternativeKey].toString();
    }

    return '';
  }

  String _formatListField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List && value.isNotEmpty) {
      return value.join(', ');
    } else if (value is String && value.isNotEmpty && value != 'null') {
      return value;
    }
    return '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _genderController.dispose();
    _meetLinkController.dispose();
    _experienceController.dispose();
    _expertiseController.dispose();
    _languagesController.dispose();
    _qualificationsController.dispose();
    _chargeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<bool> _updateProfilePicture() async {
    if (_selectedImage == null) return false;

    try {
      final result = await _apiService.updateUserProfilePicture(
        _selectedImage!,
      );

      if (result['success'] == true) {
        if (result['data'] != null) {
          final responseData = result['data'];
          if (responseData is Map<String, dynamic>) {
            final newPictureUrl =
                responseData['profile_picture'] ??
                responseData['pictureUrl'] ??
                responseData['profilePicture'];
            if (newPictureUrl != null) {
              setState(() {
                _currentProfilePicture = newPictureUrl.toString();
                _selectedImage = null;
              });
            }
          }
        }
        return true;
      } else {
        _showError(result['error'] ?? 'Failed to update profile picture');
        return false;
      }
    } catch (e) {
      _showError('Error updating profile picture: $e');
      return false;
    }
  }

  // Flatten any nested list into a comma-separated string
  /// Parses nested list-like structures coming either as actual List objects
  /// or as Strings that look like bracketed lists (e.g. "[[MA]]") and returns
  /// a comma-separated String like "MA, PhD".
  String _parseNestedListField(dynamic fieldData) {
    // Helper: split top-level comma-separated items inside a bracketed string.
    List<String> _splitTopLevel(String s) {
      final List<String> parts = [];
      final sb = StringBuffer();
      int bracket = 0;

      for (int i = 0; i < s.length; i++) {
        final ch = s[i];
        if (ch == '[') {
          bracket++;
          sb.write(ch);
        } else if (ch == ']') {
          bracket--;
          sb.write(ch);
        } else if (ch == ',' && bracket == 0) {
          parts.add(sb.toString());
          sb.clear();
        } else {
          sb.write(ch);
        }
      }

      if (sb.isNotEmpty) parts.add(sb.toString());
      return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    }

    // Normalize single token: remove surrounding quotes if present, trim whitespace
    String _normalizeToken(String token) {
      var t = token.trim();
      if ((t.startsWith('"') && t.endsWith('"')) ||
          (t.startsWith("'") && t.endsWith("'"))) {
        t = t.substring(1, t.length - 1);
      }
      return t;
    }

    // Recursive flatten function that handles Lists and Strings (including bracketed strings)
    List<String> _flatten(dynamic data) {
      if (data == null) return [];

      // If it's already a List, recurse into each item
      if (data is List) {
        final List<String> out = [];
        for (var item in data) {
          out.addAll(_flatten(item));
        }
        return out;
      }

      // If it's a string that looks like a bracketed list "[...]", parse its contents
      if (data is String) {
        final s = data.trim();
        if (s.startsWith('[') && s.endsWith(']')) {
          // remove outer [ ]
          final inner = s.substring(1, s.length - 1);
          // split top-level items (handles nested brackets)
          final parts = _splitTopLevel(inner);
          final List<String> out = [];
          for (var p in parts) {
            // recursively flatten each part (in case of nested brackets)
            out.addAll(_flatten(p));
          }
          return out;
        }

        // Plain string token (no brackets) — normalize and return
        return [_normalizeToken(s)];
      }

      // Fallback: convert other value types to string
      return [data.toString()];
    }

    try {
      final flatList = _flatten(fieldData);
      // remove empties and duplicates if you want:
      final cleaned = flatList
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      print("Flattened qualifications: $cleaned"); // debug
      return cleaned.join(', ');
    } catch (e) {
      print("Error flattening fieldData: $e");
      return '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool pictureUpdated = false;
      if (_selectedImage != null) {
        pictureUpdated = await _updateProfilePicture();
      }

      final backendAvailability = _generateBackendAvailability();

      final result = await _apiService.updateTherapistProfile(
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        meetLink: _meetLinkController.text.trim().isEmpty
            ? null
            : _meetLinkController.text.trim(),
        experience: _experienceController.text.trim().isEmpty
            ? null
            : _experienceController.text.trim(),
        expertise: _expertiseController.text.trim().isEmpty
            ? null
            : _expertiseController.text.trim(),
        languages: _languagesController.text.trim().isEmpty
            ? null
            : _languagesController.text.trim(),
        qualifications: _qualificationsController.text.trim().isEmpty
            ? null
            : _qualificationsController.text.trim(),
        charge: _chargeController.text.trim().isEmpty
            ? null
            : _chargeController.text.trim(),
        availability: backendAvailability.isEmpty
            ? null
            : jsonEncode(backendAvailability),
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (result['success'] == true || pictureUpdated) {
        _showSuccess('Profile updated successfully');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop(true);
      } else {
        _showError(result['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('Error updating profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ColorConstants.redColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ColorConstants.color2E7D7D,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.colorF5F5F5,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfilePictureSection(),
              SizedBox(height: 24),
              _buildBasicInfoSection(),
              SizedBox(height: 20),
              _buildProfessionalInfoSection(),
              SizedBox(height: 20),
              _buildAvailabilitySection(),
              SizedBox(height: 20),
              _buildAboutSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return _buildSection('Availability', Icons.schedule, [
      Text(
        'Select your available time slots for each day',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
      SizedBox(height: 16),
      ..._availability.keys.map((day) => _buildDayAvailability(day)).toList(),
    ]);
  }

  Widget _buildDayAvailability(String day) {
    final daySlots = _timeSlotsByDay[day]!;
    final selectedSlots = _availability[day]!;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: ColorConstants.primaryBrownColor,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _availability[day] = Set<String>.from(daySlots);
                      });
                    },
                    child: Text('All', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _availability[day]!.clear();
                      });
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: daySlots.map((timeSlot) {
              final isSelected = selectedSlots.contains(timeSlot);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _availability[day]!.remove(timeSlot);
                    } else {
                      _availability[day]!.add(timeSlot);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorConstants.primaryBrownColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? ColorConstants.primaryBrownColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    timeSlot,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedSlots.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              '${selectedSlots.length} slots selected',
              style: TextStyle(
                fontSize: 12,
                color: ColorConstants.primaryBrownColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
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
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : _currentProfilePicture != null &&
                            _currentProfilePicture!.isNotEmpty
                      ? Image.network(
                          _currentProfilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorConstants.primaryBrownColor,
                                ),
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryBrownColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _selectedImage != null
                ? 'New photo selected - tap Save to update'
                : 'Tap camera icon to change profile picture',
            style: TextStyle(
              color: _selectedImage != null
                  ? Colors.blue.shade600
                  : Colors.grey.shade600,
              fontSize: 14,
              fontWeight: _selectedImage != null
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection('Basic Information', Icons.person, [
      _buildTextField(
        controller: _fullNameController,
        label: 'Full Name',
        hint: 'Enter your full name',
        validator: (value) {
          if (value?.trim().isEmpty == true) {
            return 'Please enter your full name';
          }
          return null;
        },
      ),
      SizedBox(height: 16),
      _buildDropdownField(
        controller: _genderController,
        label: 'Gender',
        hint: 'Select your gender',
        items: ['Male', 'Female', 'Other', 'Prefer not to say'],
      ),
      SizedBox(height: 16),
      _buildTextField(
        controller: _meetLinkController,
        label: 'Meeting Link',
        hint: 'Enter your video meeting link (Google Meet, Zoom, etc.)',
        keyboardType: TextInputType.url,
      ),
    ]);
  }

  Widget _buildProfessionalInfoSection() {
    return _buildSection('Professional Information', Icons.work, [
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _experienceController,
              label: 'Experience (Years)',
              hint: 'e.g., 5',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: _chargeController,
              label: 'Consultation Fee',
              hint: 'e.g., 800',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      SizedBox(height: 16),
      _buildTextField(
        controller: _expertiseController,
        label: 'Expertise',
        hint: 'e.g., Anxiety, Depression, Relationship Counseling',
        maxLines: 2,
        helperText: 'Separate multiple items with commas',
      ),
      SizedBox(height: 16),
      _buildTextField(
        controller: _languagesController,
        label: 'Languages',
        hint: 'e.g., English, Hindi, Bengali',
        helperText: 'Separate multiple languages with commas',
      ),
      SizedBox(height: 16),
      _buildTextField(
        controller: _qualificationsController,
        label: 'Qualifications',
        hint: 'e.g., M.A. Psychology, Ph.D. Clinical Psychology',
        maxLines: 2,
        helperText: 'Separate multiple qualifications with commas',
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSection('About Me', Icons.info, [
      _buildTextField(
        controller: _messageController,
        label: 'Professional Message',
        hint: 'Write a brief description about yourself and your approach...',
        maxLines: 5,
      ),
    ]);
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.brown.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primaryBrownColor,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorConstants.primaryBrownColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ColorConstants.primaryBrownColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorConstants.primaryBrownColor,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          hint: Text(hint),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ColorConstants.primaryBrownColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              controller.text = newValue ?? '';
              _genderController.text = controller.text;
            });
          },
        ),
      ],
    );
  }
}
