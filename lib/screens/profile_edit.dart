import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:therapist_app/core/api_service.dart';
import 'package:therapist_app/core/authservices.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';
import 'dart:io';

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
  final _availabilityController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentProfilePicture;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;

      // Map API response fields to form controllers based on actual API structure
      _fullNameController.text = _getFieldValue(
        data,
        'fullName',
        'fullname',
      ); // API uses 'fullname'
      _genderController.text = _getFieldValue(data, 'gender');
      print("gender selected data ${_genderController.text}");
      _meetLinkController.text = _getFieldValue(data, 'meetLink');
      _experienceController.text = _getFieldValue(data, 'experience');

      // Handle list fields (expertise, languages)
      _expertiseController.text = _formatListField(data, 'expertise');
      _languagesController.text = _formatListField(data, 'languages');
      _qualificationsController.text = _getFieldValue(data, 'qualifications');

      _chargeController.text = _getFieldValue(data, 'charge');
      _availabilityController.text = _getFieldValue(data, 'availability');
      _messageController.text = _getFieldValue(data, 'message');

      // Handle profile picture - API uses 'pictureUrl'
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

  String _getFieldValue(
    Map<String, dynamic> data,
    String key, [
    String? alternativeKey,
  ]) {
    // Try primary key first
    if (data.containsKey(key) &&
        data[key] != null &&
        data[key].toString().isNotEmpty &&
        data[key].toString() != 'Not Available' &&
        data[key].toString() != 'null') {
      return data[key].toString();
    }

    // Try alternative key if provided
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
    _availabilityController.dispose();
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
      print('Updating profile picture...');
      final result = await _apiService.updateUserProfilePicture(
        _selectedImage!,
      );

      print('Profile picture update result: $result');

      if (result['success'] == true) {
        // Update current profile picture URL if provided in response
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
                _selectedImage = null; // Clear selected image
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
      print('Error updating profile picture: $e');
      _showError('Error updating profile picture: $e');
      return false;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update profile picture first if selected
      bool pictureUpdated = false;
      if (_selectedImage != null) {
        final pictureResult = await _updateProfilePicture();
        if (pictureResult) {
          pictureUpdated = true;
        }
      }

      print('Updating therapist profile...');
      
      // Prepare data for profile update - using correct API field names
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
        availability: _availabilityController.text.trim().isEmpty
            ? null
            : _availabilityController.text.trim(),
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      print('Profile update result: $result');

      if (result['success'] == true || pictureUpdated) {
        _showSuccess('Profile updated successfully');

        // Wait a moment for the success message to show
        await Future.delayed(const Duration(seconds: 1));

        // Go back to profile screen with refresh flag
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        _showError(result['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
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
        title: Text('Edit Profile'),
        backgroundColor: Colors.brown.shade600,
        foregroundColor: Colors.white,
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
              _buildAboutSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
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
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey.shade400,
                            );
                          },
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
      SizedBox(height: 16),
      _buildTextField(
        controller: _availabilityController,
        label: 'Availability',
        hint: 'e.g., Mon-Fri 9AM-6PM, Weekends by appointment',
        maxLines: 2,
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
              print("selected gender ${controller.text}");
              _genderController.text = controller.text;
            });
          },
        ),
      ],
    );
  }
}
