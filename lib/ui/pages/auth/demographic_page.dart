import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/hooks/auth/auth_hook.dart';
import 'package:social_media_app/data/services/user/user_service.dart';

class OnboardingDemographicPage extends StatefulWidget {
  const OnboardingDemographicPage({super.key});

  @override
  State<OnboardingDemographicPage> createState() =>
      _OnboardingDemographicPageState();
}

class _OnboardingDemographicPageState extends State<OnboardingDemographicPage> {
  final AuthHook _authHook = AuthHook();
  final UserService _userService = UserService();

  // Form controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();

  // Selected values
  String _selectedGender = '';
  String _selectedLookingFor = '';
  List<String> _selectedInterests = [];

  bool _isLoading = false;
  int _currentStep = 0;

  // Options
  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];
  final List<String> _lookingForOptions = [
    'Friendship',
    'Dating',
    'Networking',
    'Casual',
    'Serious Relationship'
  ];
  final List<String> _interestsList = [
    'Music',
    'Sports',
    'Travel',
    'Food',
    'Art',
    'Fashion',
    'Technology',
    'Reading',
    'Gaming',
    'Photography',
    'Dancing',
    'Yoga',
    'Hiking',
    'Movies',
    'Cooking',
    'Fitness'
  ];

  final List<String> _ageRange = List.generate(63, (i) => (18 + i).toString());

  @override
  void dispose() {
    _ageController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _workController.dispose();
    _educationController.dispose();
    _authHook.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.greyColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _currentStep == 0
                  ? _buildBasicInfoStep()
                  : _currentStep == 1
                      ? _buildProfileStep()
                      : _buildInterestsStep(),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Basic Info'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? AppColors.primary
                  : AppColors.greyColor.withOpacity(0.3),
            ),
          ),
          _buildStepIndicator(1, 'Profile'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2
                  ? AppColors.primary
                  : AppColors.greyColor.withOpacity(0.3),
            ),
          ),
          _buildStepIndicator(2, 'Interests'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.primary
                : AppColors.greyColor.withOpacity(0.3),
            border: isActive && !isCompleted
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    (step + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.greyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTheme.greyTextStyle.copyWith(
            fontSize: 10,
            color: isActive ? AppColors.primary : AppColors.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 28,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildDropdownField(
            label: 'Age',
            value: _ageController.text.isEmpty ? null : _ageController.text,
            items: _ageRange,
            hint: 'Select your age',
            onChanged: (value) {
              setState(() {
                _ageController.text = value ?? '';
              });
            },
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Gender',
            value: _selectedGender.isEmpty ? null : _selectedGender,
            items: _genders,
            hint: 'Select your gender',
            onChanged: (value) {
              setState(() {
                _selectedGender = value ?? '';
              });
            },
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Looking For',
            value: _selectedLookingFor.isEmpty ? null : _selectedLookingFor,
            items: _lookingForOptions,
            hint: 'What are you looking for?',
            onChanged: (value) {
              setState(() {
                _selectedLookingFor = value ?? '';
              });
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            hint: 'City, Country',
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Details',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 28,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help others get to know you',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _occupationController,
            label: 'Occupation',
            hint: 'What do you do?',
            icon: Icons.work_outline,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _workController,
            label: 'Work',
            hint: 'Where do you work?',
            icon: Icons.business_center_outlined,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _educationController,
            label: 'Education',
            hint: 'Where did you study?',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _bioController,
            label: 'Bio',
            hint: 'Tell us about yourself...',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Interests',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 28,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 3 interests',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _interestsList.map((interest) {
              bool isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                backgroundColor: AppColors.backgroundColor,
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: AppTheme.blackTextStyle.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.blackColor,
                  fontSize: 14,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.greyColor.withOpacity(0.3),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedInterests.length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Selected: ${_selectedInterests.length}/3',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 12,
                  color: _selectedInterests.length < 3
                      ? AppColors.redColor
                      : AppColors.greenColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.greyColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: AppTheme.blackTextStyle.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.greyColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.greyColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.greyColor),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: AppTheme.blackTextStyle.copyWith(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.greyColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: GestureDetector(
                onTap: _isLoading ? null : _goToPreviousStep,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.greyColor.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: AppTheme.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _goToNextStep,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentStep == 2 ? 'Complete' : 'Next',
                          style: AppTheme.whiteTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: AppTheme.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      if (_ageController.text.isEmpty ||
          _selectedGender.isEmpty ||
          _selectedLookingFor.isEmpty) {
        _showSnack('Please fill all required fields');
        return;
      }
    }

    if (_currentStep == 2) {
      if (_selectedInterests.length < 3) {
        _showSnack('Please select at least 3 interests');
        return;
      }
      _saveDemographicInfo();
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  void _goToPreviousStep() {
    setState(() {
      _currentStep--;
    });
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _saveDemographicInfo() async {
    setState(() => _isLoading = true);

    try {
      await _userService.updateDemographicInfo(
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        lookingFor: _selectedLookingFor,
        occupation: _occupationController.text,
        bio: _bioController.text,
        location: _locationController.text,
        work: _workController.text,
        education: _educationController.text,
        interests: _selectedInterests,
      );

      await _userService.completeOnboarding();

      if (mounted) {
        Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      await _userService.completeOnboarding();

      if (mounted) {
        Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.redColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
