import 'dart:io';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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

  File? _selectedAvatarFile;
  File? _selectedCoverFile;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _loadData() {
    context.read<ProfileBloc>().add(LoadMyProfile());
    context.read<UserBloc>().add(LoadCurrentUser());
  }

  void _populateForm(Profile? profile, Map<String, dynamic>? user) {
    if (profile == null && user == null) return;

    setState(() {
      // From ProfileBloc
      _nameController.text = profile?.displayName ?? user?['name'] ?? '';
      _bioController.text = profile?.bio ?? '';
      _locationController.text = profile?.location ?? '';
      _workController.text = profile?.work ?? '';
      _educationController.text = profile?.education ?? '';
      _ageController.text =
          profile?.age.toString() ?? user?['age']?.toString() ?? '';

      // Languages
      if (profile?.interests.isNotEmpty == true) {
        _languagesController.text = profile!.interests.join(', ');
      }

      // From UserBloc
      _usernameController.text = user?['username'] ?? '';
      _phoneController.text = user?['phone'] ?? '';
      _occupationController.text = user?['occupation'] ?? '';
    });
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

        // Upload immediately
        await _uploadImage(File(pickedFile.path), isAvatar);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
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
      final imageUrl =
          await _cloudinaryService.uploadImage(imageFile, customFolder: folder);

      if (isAvatar) {
        context
            .read<ProfileBloc>()
            .add(UpdateProfileAvatar(avatarUrl: imageUrl));
      } else {
        context
            .read<ProfileBloc>()
            .add(UpdateProfileCoverImage(coverImageUrl: imageUrl));
      }

      _showSnackBar('${isAvatar ? 'Profile picture' : 'Cover image'} updated');
    } catch (e) {
      _showSnackBar('Error uploading image: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          if (isAvatar) {
            _isUploadingAvatar = false;
            _selectedAvatarFile = null;
          } else {
            _isUploadingCover = false;
            _selectedCoverFile = null;
          }
        });
      }
    }
  }

  void _showImagePickerOptions(bool isAvatar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
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
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
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

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final languages = _languagesController.text.isNotEmpty
        ? _languagesController.text.split(',').map((e) => e.trim()).toList()
        : null;

    // Update via ProfileBloc
    context.read<ProfileBloc>().add(UpdateProfile(
          data: {
            'displayName':
                _nameController.text.isNotEmpty ? _nameController.text : null,
            'bio': _bioController.text.isNotEmpty ? _bioController.text : null,
            'location': _locationController.text.isNotEmpty
                ? _locationController.text
                : null,
            'work':
                _workController.text.isNotEmpty ? _workController.text : null,
            'education': _educationController.text.isNotEmpty
                ? _educationController.text
                : null,
            'age': _ageController.text.isNotEmpty
                ? int.parse(_ageController.text)
                : null,
            'interests': languages,
          },
        ));

    // Update via UserBloc for remaining fields
    context.read<UserBloc>().add(UpdateUser(
          name: _nameController.text.isNotEmpty ? _nameController.text : null,
          username: _usernameController.text.isNotEmpty
              ? _usernameController.text
              : null,
          phone:
              _phoneController.text.isNotEmpty ? _phoneController.text : null,
          age: _ageController.text.isNotEmpty
              ? int.parse(_ageController.text)
              : null,
          occupation: _occupationController.text.isNotEmpty
              ? _occupationController.text
              : null,
        ));

    _showSnackBar('Profile updated successfully');
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.text),
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
              'Save',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.primary,
                fontWeight: AppTheme.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.success ||
              state.status == ProfileStatus.error) {
            setState(() => _isSaving = false);
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
            return BlocBuilder<UserBloc, UserState>(
              builder: (context, userState) {
                if (profileState.status == ProfileStatus.loading ||
                    userState.status == UserStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // Populate form when data is loaded
                if (profileState.status == ProfileStatus.success ||
                    userState.status == UserStatus.success) {
                  _populateForm(profileState.myProfile, userState.currentUser);
                }

                final profile = profileState.myProfile;
                final user = userState.currentUser;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCoverImageSection(profile),
                      const SizedBox(height: 16),
                      _buildProfilePictureSection(profile),
                      const SizedBox(height: 24),
                      _buildFormFields(),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoverImageSection(Profile? profile) {
    final hasCover = _selectedCoverFile != null ||
        (profile?.coverImage != null && profile!.coverImage!.isNotEmpty);

    return GestureDetector(
      onTap: () => _showImagePickerOptions(false),
      child: Container(
        height: 180,
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (_selectedCoverFile != null)
                Image.file(_selectedCoverFile!,
                    fit: BoxFit.cover, width: double.infinity)
              else if (profile?.coverImage != null &&
                  profile!.coverImage!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: profile.coverImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) =>
                      Container(color: AppColors.greyColor.withOpacity(0.1)),
                  errorWidget: (context, url, error) =>
                      _buildCoverPlaceholder(),
                )
              else
                _buildCoverPlaceholder(),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: _isUploadingCover
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: AppColors.greyColor.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 40, color: AppColors.greyColor),
            const SizedBox(height: 8),
            Text('Add cover photo',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(Profile? profile) {
    final hasAvatar = _selectedAvatarFile != null ||
        (profile?.avatar != null && profile!.avatar!.isNotEmpty);
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : 'U';

    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: _selectedAvatarFile != null
                    ? Image.file(_selectedAvatarFile!, fit: BoxFit.cover)
                    : (profile?.avatar != null && profile!.avatar!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profile.avatar!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                                color: AppColors.greyColor.withOpacity(0.1)),
                            errorWidget: (context, url, error) =>
                                _avatarFallback(initial),
                          )
                        : _avatarFallback(initial)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImagePickerOptions(true),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isUploadingAvatar
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'Enter your name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter username',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone',
            hint: 'Enter phone number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _ageController,
            label: 'Age',
            hint: 'Enter your age',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _occupationController,
            label: 'Occupation',
            hint: 'What do you do?',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bioController,
            label: 'Bio',
            hint: 'Write a bio...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            hint: 'Where are you located?',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _workController,
            label: 'Work',
            hint: 'Where do you work?',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _educationController,
            label: 'Education',
            hint: 'Where did you study?',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _languagesController,
            label: 'Languages',
            hint: 'English, French, Spanish...',
            maxLines: 2,
          ),
        ],
      ),
    );
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: AppTheme.blackTextStyle.copyWith(fontSize: 15),
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
