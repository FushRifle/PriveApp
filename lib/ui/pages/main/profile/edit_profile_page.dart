import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController(text: 'Fush');
  final _usernameController = TextEditingController(text: '@fush.co');
  final _bioController = TextEditingController(
      text:
          'Digital creator | Photographer 📸\nLiving life one frame at a time');
  final _websiteController = TextEditingController(text: 'www.fush.co');
  String _gender = 'Male';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
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
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Done',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.purpleColor,
                fontWeight: AppTheme.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                        border:
                            Border.all(color: AppColors.purpleColor, width: 3),
                        image: const DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage('assets/images/img_profile.jpeg'),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.purpleColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
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

              // Bio field
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Write a bio...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Website field
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                hint: 'Add website',
              ),
              const SizedBox(height: 16),

              // Gender selection
              _buildGenderSelector(),
              const SizedBox(height: 24),

              // Switch to professional account
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.purpleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work,
                          color: AppColors.purpleColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch to Professional Account',
                            style: AppTheme.blackTextStyle.copyWith(
                              fontWeight: AppTheme.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get access to insights and tools',
                            style:
                                AppTheme.greyTextStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.greyColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
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

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.medium,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Male', 'Female', 'Other'].map((gender) {
            final isSelected = _gender == gender;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = gender),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: EdgeInsets.only(
                    right: gender == 'Other' ? 0 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purpleColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.purpleColor
                          : AppColors.greyColor.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      gender,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
