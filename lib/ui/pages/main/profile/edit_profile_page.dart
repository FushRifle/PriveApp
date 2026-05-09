import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/services/user/user_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserService _userService = UserService();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _workController = TextEditingController();
  final _educationController = TextEditingController();
  final _languagesController = TextEditingController();

  String _avatar = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _workController.dispose();
    _educationController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getCurrentUser();

      setState(() {
        _avatar = userData['avatar'] ?? '';
        _nameController.text = userData['name'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _ageController.text = userData['age']?.toString() ?? '';
        _occupationController.text = userData['occupation'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _locationController.text = userData['location'] ?? '';
        _workController.text = userData['work'] ?? '';
        _educationController.text = userData['education'] ?? '';

        // Handle languages - could be List or comma-separated string
        final languages = userData['languages'];
        if (languages is List) {
          _languagesController.text = languages.join(', ');
        } else if (languages is String) {
          _languagesController.text = languages;
        } else {
          _languagesController.text = '';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final languages = _languagesController.text.isNotEmpty
          ? _languagesController.text.split(',').map((e) => e.trim()).toList()
          : null;

      await _userService.updateUser(
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        username: _usernameController.text.isNotEmpty
            ? _usernameController.text
            : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        age: _ageController.text.isNotEmpty
            ? int.parse(_ageController.text)
            : null,
        occupation: _occupationController.text.isNotEmpty
            ? _occupationController.text
            : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        work: _workController.text.isNotEmpty ? _workController.text : null,
        education: _educationController.text.isNotEmpty
            ? _educationController.text
            : null,
        languages: languages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changeProfilePicture() async {
    // TODO: Implement image picker
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change profile picture feature coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Done',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.primary,
                fontWeight: AppTheme.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile picture
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              backgroundImage: _avatar.isNotEmpty
                                  ? NetworkImage(_avatar)
                                  : null,
                              child: _avatar.isEmpty
                                  ? Text(
                                      _getNameInitial(),
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changeProfilePicture,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: 'Enter your name',
                    ),
                    const SizedBox(height: 16),

                    // Username field
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'Enter username',
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      hint: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Age field
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'Enter your age',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Occupation field
                    _buildTextField(
                      controller: _occupationController,
                      label: 'Occupation',
                      hint: 'What do you do?',
                    ),
                    const SizedBox(height: 16),

                    // Bio field
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'Write a bio...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Location field
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'Where are you located?',
                    ),
                    const SizedBox(height: 16),

                    // Work field
                    _buildTextField(
                      controller: _workController,
                      label: 'Work',
                      hint: 'Where do you work?',
                    ),
                    const SizedBox(height: 16),

                    // Education field
                    _buildTextField(
                      controller: _educationController,
                      label: 'Education',
                      hint: 'Where did you study?',
                    ),
                    const SizedBox(height: 16),

                    // Languages field
                    _buildTextField(
                      controller: _languagesController,
                      label: 'Languages',
                      hint: 'English, French, Spanish...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _getNameInitial() {
    final name = _nameController.text;
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.medium,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: AppTheme.blackTextStyle.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
