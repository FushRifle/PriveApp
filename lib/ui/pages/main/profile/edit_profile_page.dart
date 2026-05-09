import 'dart:io';
import 'package:Prive/core/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

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
  String _coverImage = '';
  File? _selectedAvatarFile;
  File? _selectedCoverFile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

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
        _coverImage = userData['coverImage'] ?? userData['cover_image'] ?? '';
        _nameController.text = userData['name'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _ageController.text = userData['age']?.toString() ?? '';
        _occupationController.text = userData['occupation'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _locationController.text = userData['location'] ?? '';
        _workController.text = userData['work'] ?? '';
        _educationController.text = userData['education'] ?? '';

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

  Future<void> _pickImage(ImageSource source, bool isAvatar) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isAvatar) {
            _selectedAvatarFile = File(pickedFile.path);
          } else {
            _selectedCoverFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage(File imageFile, bool isAvatar) async {
    setState(() {
      if (isAvatar) {
        _isUploadingAvatar = true;
      } else {
        _isUploadingCover = true;
      }
    });

    try {
      final folder = isAvatar ? 'avatars' : 'covers';
      final imageUrl = await _cloudinaryService.uploadImage(imageFile, folder);

      if (imageUrl != null) {
        setState(() {
          if (isAvatar) {
            _avatar = imageUrl;
            _selectedAvatarFile = null;
          } else {
            _coverImage = imageUrl;
            _selectedCoverFile = null;
          }
        });

        // Save to backend
        if (isAvatar) {
          await _userService.updateUser(avatar: imageUrl);
        } else {
          await _userService.updateUser(coverImage: imageUrl);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isAvatar ? 'Profile picture' : 'Cover image'} updated successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isAvatar) {
            _isUploadingAvatar = false;
          } else {
            _isUploadingCover = false;
          }
        });
      }
    }
  }

  void _showImagePickerOptions(bool isAvatar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isAvatar);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isAvatar);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    _showImagePickerOptions(true);
  }

  void _changeCoverImage() {
    _showImagePickerOptions(false);
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Upload avatar if selected
      if (_selectedAvatarFile != null) {
        await _uploadImage(_selectedAvatarFile!, true);
      }

      // Upload cover if selected
      if (_selectedCoverFile != null) {
        await _uploadImage(_selectedCoverFile!, false);
      }

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
        avatar: _avatar.isNotEmpty ? _avatar : null,
        coverImage: _coverImage.isNotEmpty ? _coverImage : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
            onPressed: (_isSaving || _isUploadingAvatar || _isUploadingCover)
                ? null
                : _saveProfile,
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
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Cover Image
                    _buildCoverImageSection(),
                    const SizedBox(height: 16),

                    // Profile picture
                    _buildProfilePictureSection(),
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

  Widget _buildCoverImageSection() {
    return GestureDetector(
      onTap: _changeCoverImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.greyColor.withOpacity(0.1),
          image: _selectedCoverFile != null
              ? DecorationImage(
                  image: FileImage(_selectedCoverFile!),
                  fit: BoxFit.cover,
                )
              : (_coverImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_coverImage),
                      fit: BoxFit.cover,
                    )
                  : null),
        ),
        child: Stack(
          children: [
            if (_coverImage.isEmpty && _selectedCoverFile == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: AppColors.greyColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add cover photo',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isUploadingCover
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: _selectedAvatarFile != null
                  ? FileImage(_selectedAvatarFile!)
                  : (_avatar.isNotEmpty ? NetworkImage(_avatar) : null)
                      as ImageProvider?,
              child: (_avatar.isEmpty && _selectedAvatarFile == null)
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
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isUploadingAvatar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
          ),
        ],
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
