import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

import 'package:clique/core/cloudinary_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();

  File? _selectedAvatarFile;
  File? _selectedCoverFile;

  bool _hasPopulatedForm = false;
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _cloudinaryService.cancelAllUploads();

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

  void _populateFormOnce(
    Profile? profile,
    Map<String, dynamic>? user,
  ) {
    if (_hasPopulatedForm) return;
    if (profile == null && user == null) return;

    _hasPopulatedForm = true;

    _nameController.text =
        _readString(profile?.displayName) ?? _readString(user?['name']) ?? '';

    _bioController.text = _readString(profile?.bio) ?? '';
    _locationController.text = _readString(profile?.location) ?? '';
    _workController.text = _readString(profile?.work) ?? '';
    _educationController.text = _readString(profile?.education) ?? '';

    final age = profile?.age ?? _readInt(user?['age']);
    _ageController.text = age != null && age > 0 ? age.toString() : '';

    if (profile?.interests.isNotEmpty == true) {
      _languagesController.text = profile!.interests.join(', ');
    }

    _usernameController.text = _readString(user?['username']) ?? '';
    _phoneController.text = _readString(user?['phone']) ?? '';
    _occupationController.text = _readString(user?['occupation']) ?? '';
  }

  String? _readString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);

    return null;
  }

  bool get _isBusy {
    return _isSaving ||
        _isPickingImage ||
        _isUploadingAvatar ||
        _isUploadingCover;
  }

  Future<void> _pickImage(
    ImageSource source,
    bool isAvatar,
  ) async {
    if (_isBusy) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: isAvatar ? 1200 : 1800,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      if (!mounted) return;

      setState(() {
        if (isAvatar) {
          _selectedAvatarFile = file;
        } else {
          _selectedCoverFile = file;
        }
      });

      await _uploadImage(
        imageFile: file,
        isAvatar: isAvatar,
      );
    } catch (e) {
      _showSnackBar(
        'Error picking image: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _uploadImage({
    required File imageFile,
    required bool isAvatar,
  }) async {
    if (!mounted) return;

    setState(() {
      if (isAvatar) {
        _isUploadingAvatar = true;
      } else {
        _isUploadingCover = true;
      }
    });

    try {
      final folder = isAvatar ? 'avatars' : 'covers';

      final imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        customFolder: folder,
      );

      if (!mounted) return;

      if (isAvatar) {
        context.read<ProfileBloc>().add(
              UpdateProfileAvatar(
                avatarUrl: imageUrl,
              ),
            );
      } else {
        context.read<ProfileBloc>().add(
              UpdateProfileCoverImage(
                coverImageUrl: imageUrl,
              ),
            );
      }

      _showSnackBar(
        '${isAvatar ? 'Profile picture' : 'Cover image'} updated',
      );
    } catch (e) {
      _showSnackBar(
        'Error uploading image: $e',
        isError: true,
      );
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
    if (_isBusy) return;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _PickerTile(
                  icon: Icons.camera_alt,
                  title: 'Take a photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isAvatar);
                  },
                ),
                _PickerTile(
                  icon: Icons.photo_library,
                  title: 'Choose from gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isAvatar);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    final age = int.tryParse(_ageController.text.trim());

    if (_ageController.text.trim().isNotEmpty && age == null) {
      _showSnackBar(
        'Please enter a valid age',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final languages = _languagesController.text.trim().isNotEmpty
        ? _languagesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : null;

    try {
      context.read<ProfileBloc>().add(
            UpdateProfile(
              data: {
                'displayName': _nullableText(_nameController),
                'bio': _nullableText(_bioController),
                'location': _nullableText(_locationController),
                'work': _nullableText(_workController),
                'education': _nullableText(_educationController),
                'age': age,
                'interests': languages,
              },
            ),
          );

      context.read<UserBloc>().add(
            UpdateUser(
              name: _nullableText(_nameController),
              username: _nullableText(_usernameController),
              phone: _nullableText(_phoneController),
              age: age,
              occupation: _nullableText(_occupationController),
            ),
          );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showSnackBar(
        'Error saving profile: $e',
        isError: true,
      );
    }
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  void _onSaveFinished({
    required bool success,
    String? error,
  }) {
    if (!_isSaving) return;

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!success) {
      _showSnackBar(
        error ?? 'Unable to update profile',
        isError: true,
      );
      return;
    }

    _showSnackBar('Profile updated successfully');

    Navigator.pop(context, true);
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) {
            return previous.status != current.status;
          },
          listener: (context, state) {
            if (state.status == ProfileStatus.error) {
              _onSaveFinished(
                success: false,
                error: state.error,
              );
            }

            if (state.status == ProfileStatus.success && _isSaving) {
              _onSaveFinished(
                success: true,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: AppColors.text,
            ),
            onPressed: _isBusy ? null : () => Navigator.pop(context),
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
              onPressed: _isBusy ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTheme.blackTextStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTheme.bold,
                      ),
                    ),
            ),
          ],
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (previous, current) {
            return previous.status != current.status ||
                previous.myProfile != current.myProfile;
          },
          builder: (context, profileState) {
            return BlocBuilder<UserBloc, UserState>(
              buildWhen: (previous, current) {
                return previous.status != current.status ||
                    previous.currentUser != current.currentUser;
              },
              builder: (context, userState) {
                final profile = profileState.myProfile;
                final user = userState.currentUser;

                final loading = !_hasPopulatedForm &&
                    (profileState.status == ProfileStatus.loading ||
                        userState.status == UserStatus.loading);

                if (loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }

                _populateFormOnce(profile, user);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(
                    bottom: 32,
                  ),
                  child: Column(
                    children: [
                      _CoverImageSection(
                        profile: profile,
                        selectedCoverFile: _selectedCoverFile,
                        isUploading: _isUploadingCover,
                        isDisabled: _isBusy,
                        onTap: () => _showImagePickerOptions(false),
                      ),
                      const SizedBox(height: 16),
                      _ProfilePictureSection(
                        profile: profile,
                        selectedAvatarFile: _selectedAvatarFile,
                        isUploading: _isUploadingAvatar,
                        isDisabled: _isBusy,
                        initial: _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : 'U',
                        onTap: () => _showImagePickerOptions(true),
                      ),
                      const SizedBox(height: 24),
                      _FormFields(
                        nameController: _nameController,
                        usernameController: _usernameController,
                        phoneController: _phoneController,
                        ageController: _ageController,
                        occupationController: _occupationController,
                        bioController: _bioController,
                        locationController: _locationController,
                        workController: _workController,
                        educationController: _educationController,
                        languagesController: _languagesController,
                        enabled: !_isBusy,
                      ),
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
}

class _CoverImageSection extends StatelessWidget {
  final Profile? profile;
  final File? selectedCoverFile;
  final bool isUploading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _CoverImageSection({
    required this.profile,
    required this.selectedCoverFile,
    required this.isUploading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = profile?.coverImage ?? '';

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
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
            fit: StackFit.expand,
            children: [
              if (selectedCoverFile != null)
                Image.file(
                  selectedCoverFile!,
                  fit: BoxFit.cover,
                )
              else if (coverUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) {
                    return Container(
                      color: AppColors.greyColor.withOpacity(0.1),
                    );
                  },
                  errorWidget: (_, __, ___) {
                    return const _CoverPlaceholder();
                  },
                )
              else
                const _CoverPlaceholder(),
              Positioned(
                bottom: 12,
                right: 12,
                child: _CameraBadge(
                  isLoading: isUploading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.greyColor.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: AppColors.greyColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Add cover photo',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePictureSection extends StatelessWidget {
  final Profile? profile;
  final File? selectedAvatarFile;
  final bool isUploading;
  final bool isDisabled;
  final String initial;
  final VoidCallback onTap;

  const _ProfilePictureSection({
    required this.profile,
    required this.selectedAvatarFile,
    required this.isUploading,
    required this.isDisabled,
    required this.initial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = profile?.avatar ?? '';

    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
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
                child: selectedAvatarFile != null
                    ? Image.file(
                        selectedAvatarFile!,
                        fit: BoxFit.cover,
                      )
                    : avatar.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatar,
                            fit: BoxFit.cover,
                            placeholder: (_, __) {
                              return _AvatarFallback(initial: initial);
                            },
                            errorWidget: (_, __, ___) {
                              return _AvatarFallback(initial: initial);
                            },
                          )
                        : _AvatarFallback(initial: initial),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: isDisabled ? null : onTap,
              child: _CameraBadge(
                isLoading: isUploading,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initial;

  const _AvatarFallback({
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  final bool isLoading;
  final double size;

  const _CameraBadge({
    required this.isLoading,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size <= 34 ? 7 : 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            )
          : const Icon(
              Icons.camera_alt,
              color: AppColors.white,
              size: 18,
            ),
    );
  }
}

class _FormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController phoneController;
  final TextEditingController ageController;
  final TextEditingController occupationController;
  final TextEditingController bioController;
  final TextEditingController locationController;
  final TextEditingController workController;
  final TextEditingController educationController;
  final TextEditingController languagesController;
  final bool enabled;

  const _FormFields({
    required this.nameController,
    required this.usernameController,
    required this.phoneController,
    required this.ageController,
    required this.occupationController,
    required this.bioController,
    required this.locationController,
    required this.workController,
    required this.educationController,
    required this.languagesController,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        children: [
          _ProfileTextField(
            controller: nameController,
            label: 'Name',
            hint: 'Enter your name',
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: usernameController,
            label: 'Username',
            hint: 'Enter username',
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: phoneController,
            label: 'Phone',
            hint: 'Enter phone number',
            keyboardType: TextInputType.phone,
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: ageController,
            label: 'Age',
            hint: 'Enter your age',
            keyboardType: TextInputType.number,
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: occupationController,
            label: 'Occupation',
            hint: 'What do you do?',
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: bioController,
            label: 'Bio',
            hint: 'Write a bio...',
            maxLines: 3,
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: locationController,
            label: 'Location',
            hint: 'Where are you located?',
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: workController,
            label: 'Work',
            hint: 'Where do you work?',
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: educationController,
            label: 'Education',
            hint: 'Where did you study?',
            enabled: enabled,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            controller: languagesController,
            label: 'Languages',
            hint: 'English, French, Spanish...',
            maxLines: 2,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final bool enabled;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
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
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: keyboardType == TextInputType.number
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                  ]
                : null,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
}
