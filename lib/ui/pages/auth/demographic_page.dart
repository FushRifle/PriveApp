import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OnboardingDemographicPage extends StatefulWidget {
  const OnboardingDemographicPage({super.key});

  @override
  State<OnboardingDemographicPage> createState() =>
      _OnboardingDemographicPageState();
}

class _OnboardingDemographicPageState extends State<OnboardingDemographicPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final List<Animation<double>> _slideAnimations;

  // Form controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  String? _selectedAvatarUrl;
  String? _selectedCoverUrl;

  final List<String> _avatarOptions = [
    'https://cdn.pixabay.com/photo/2020/07/14/13/07/avatar-5404763_640.png',
    'https://cdn.pixabay.com/photo/2016/08/08/09/17/avatar-1577909_640.png',
    'https://cdn.pixabay.com/photo/2017/01/31/21/23/avatar-2027366_640.png',
    'https://cdn.pixabay.com/photo/2013/07/13/10/07/avatar-156584_640.png',
  ];

  final List<String> _coverOptions = [
    'https://images.pexels.com/photos/886521/pexels-photo-886521.jpeg',
    'https://images.pexels.com/photos/1261728/pexels-photo-1261728.jpeg',
    'https://images.pexels.com/photos/998641/pexels-photo-998641.jpeg',
    'https://images.pexels.com/photos/167699/pexels-photo-167699.jpeg',
  ];

  String _selectedGender = '';
  String _selectedLookingFor = '';
  final List<String> _selectedInterests = [];

  int _currentPage = 0;
  bool _isSkipping = false;
  bool _isCompletingOnboarding = false;
  bool _isSavingDemographics = false;

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

  final List<String> _pageTitles = [
    'Let\'s start with\nthe basics',
    'Tell us more\nabout yourself',
    'What are you\ninto?'
  ];

  final List<String> _pageSubtitles = [
    'This helps us find your perfect match',
    'Show others what makes you unique',
    'Connect with people who share your passions'
  ];

  DateTime? _selectedDateOfBirth;

  int get _calculatedAge {
    if (_selectedDateOfBirth == null) return 0;
    final today = DateTime.now();
    int age = today.year - _selectedDateOfBirth!.year;
    if (today.month < _selectedDateOfBirth!.month ||
        (today.month == _selectedDateOfBirth!.month &&
            today.day < _selectedDateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        ),
      );
    });
    _fadeController.forward();
    _loadExistingData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userBloc = context.read<UserBloc>();
      if (userBloc.hasAuthToken &&
          userBloc.state.currentUser == null &&
          userBloc.state.status != UserStatus.loading) {
        userBloc.add(LoadCurrentUser());
      }
    });
  }

  void _loadExistingData() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState.myProfile != null) {
      final profile = profileState.myProfile!;
      setState(() {
        _displayNameController.text = profile.displayName ?? '';
        _bioController.text = profile.bio ?? '';
        _locationController.text = profile.location ?? '';
        _workController.text = profile.work ?? '';
        _educationController.text = profile.education ?? '';
        _selectedGender = profile.gender ?? '';
        _selectedLookingFor = profile.lookingFor ?? '';
        _selectedInterests.addAll(profile.interests);
        _selectedAvatarUrl = profile.avatar;
        _selectedCoverUrl = profile.coverImage;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _ageController.dispose();
    _displayNameController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _workController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (_isSavingDemographics && state.status == ProfileStatus.success) {
            _isSavingDemographics = false;
            _completeOnboardingAndGoHome();
          }
          if (_isSavingDemographics &&
              state.status == ProfileStatus.error &&
              state.error != null) {
            _isSavingDemographics = false;
            _showSnack(state.error!);
          }
        },
        builder: (context, state) {
          final userState = context.watch<UserBloc>().state;
          final isLoading = state.isSaving ||
              userState.isLoading ||
              userState.isSaving ||
              _isCompletingOnboarding;
          return _buildContent(isLoading);
        },
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimations[_currentPage].value),
          child: Opacity(
            opacity: 1 - (_slideAnimations[_currentPage].value / 40),
            child: Column(
              children: [
                _buildSkipButton(isLoading),
                _buildPageIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildBasicInfoStep(),
                      _buildProfileStep(),
                      _buildInterestsStep(),
                    ],
                  ),
                ),
                _buildBottomButtons(isLoading),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkipButton(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, right: 20),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: isLoading ? null : _skipOnboarding,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              'Skip',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: _currentPage == index ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color:
                _currentPage == index ? AppColors.primary : AppColors.secondary,
          ),
        );
      }),
    );
  }

  // ==================== BASIC INFO STEP ====================

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            _pageTitles[0],
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 32,
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _pageSubtitles[0],
            style: AppTheme.greyTextStyle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 32),
          _buildAvatarSection(),
          const SizedBox(height: 16),
          _buildCoverSection(),
          const SizedBox(height: 16),
          _buildDisplayNameField(),
          const SizedBox(height: 16),
          _buildDateOfBirthField(),
          const SizedBox(height: 16),
          _buildGenderSection(),
          const SizedBox(height: 16),
          _buildLookingForSection(),
          const SizedBox(height: 16),
          _buildLocationField(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return _buildFormCard(
      icon: Icons.face,
      iconColors: [AppColors.secondary, AppColors.primary],
      title: 'Profile Picture',
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: _showAvatarPicker,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  image: _selectedAvatarUrl != null
                      ? DecorationImage(
                          image:
                              CachedNetworkImageProvider(_selectedAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: AppColors.card,
                ),
                child: _selectedAvatarUrl == null
                    ? Icon(Icons.add_a_photo,
                        color: AppColors.primary, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedAvatarUrl == null ? 'Add profile picture' : 'Picture set',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection() {
    return _buildFormCard(
      icon: Icons.photo,
      iconColors: [AppColors.secondary, AppColors.primary],
      title: 'Cover Photo',
      child: GestureDetector(
        onTap: _showCoverPicker,
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            image: _selectedCoverUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(_selectedCoverUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: AppColors.card,
          ),
          child: _selectedCoverUrl == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          color: AppColors.primary, size: 28),
                      const SizedBox(height: 4),
                      Text('Add cover photo',
                          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDisplayNameField() {
    return _buildFormCard(
      icon: Icons.badge,
      iconColors: [AppColors.teal, AppColors.green],
      title: 'Display Name',
      child: TextField(
        controller: _displayNameController,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'How should we call you?',
          hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return _buildFormCard(
      icon: Icons.cake,
      iconColors: [AppColors.primary, AppColors.secondary],
      title: 'Date of Birth',
      child: GestureDetector(
        onTap: _selectDateOfBirth,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                      : 'Select your date of birth',
                  style: TextStyle(
                    color: _selectedDateOfBirth != null
                        ? AppColors.black87
                        : AppColors.grey.shade500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSection() {
    return _buildFormCard(
      icon: Icons.person,
      iconColors: [AppColors.primary, AppColors.secondary],
      title: 'Gender',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _genders.map((gender) {
          final isSelected = _selectedGender == gender;
          return GestureDetector(
            onTap: () => setState(() => _selectedGender = gender),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.grey.shade300,
                ),
              ),
              child: Text(
                gender,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.text,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLookingForSection() {
    return _buildFormCard(
      icon: Icons.favorite,
      iconColors: [AppColors.orange, AppColors.red],
      title: 'I am looking for',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _lookingForOptions.map((option) {
          final isSelected = _selectedLookingFor == option;
          return GestureDetector(
            onTap: () => setState(() => _selectedLookingFor = option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.grey.shade300,
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.text,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationField() {
    return _buildFormCard(
      icon: Icons.location_on,
      iconColors: [AppColors.blue, AppColors.cyan],
      title: 'Location',
      child: TextField(
        controller: _locationController,
        style: const TextStyle(fontSize: 16,),
        decoration: InputDecoration(
          hintText: 'City, Country',
          hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ==================== PROFILE STEP ====================

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            _pageTitles[1],
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _pageSubtitles[1],
            style: AppTheme.greyTextStyle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 32),
          _buildFormCard(
            icon: Icons.work_outline,
            iconColors: [AppColors.primary, AppColors.secondary],
            title: 'Professional Info',
            child: Column(
              children: [
                _buildProfileField(
                  controller: _occupationController,
                  label: 'Occupation',
                  hint: 'What do you do?',
                  icon: Icons.work_outline,
                ),
                const Divider(height: 1),
                _buildProfileField(
                  controller: _workController,
                  label: 'Workplace',
                  hint: 'Where do you work?',
                  icon: Icons.business_center_outlined,
                ),
                const Divider(height: 1),
                _buildProfileField(
                  controller: _educationController,
                  label: 'Education',
                  hint: 'Where did you study?',
                  icon: Icons.school_outlined,
                ),
                const Divider(height: 1),
                _buildProfileField(
                  controller: _bioController,
                  label: 'Bio',
                  hint: 'Tell us about yourself...',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INTERESTS STEP ====================

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            _pageTitles[2],
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _pageSubtitles[2],
            style: AppTheme.greyTextStyle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_selectedInterests.length} interests selected',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _interestsList.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary])
                        : null,
                    color: isSelected ? null : AppColors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedInterests.length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.amber.shade700, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select at least 3 interests to help us find your perfect match',
                        style: TextStyle(
                            color: AppColors.amber.shade800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildFormCard({
    required IconData icon,
    required List<Color> iconColors,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.card,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: GestureDetector(
                onTap: isLoading ? null : _goBack,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: GestureDetector(
              onTap: isLoading ? null : _goToNextPage,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentPage == 2 ? 'Complete' : 'Continue',
                          style: AppTheme.whiteTextStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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

  // ==================== ACTIONS ====================

  void _goBack() {
    setState(() => _currentPage--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNextPage() {
    if (_currentPage == 0) {
      if (_displayNameController.text.isEmpty ||
          _selectedDateOfBirth == null ||
          _selectedGender.isEmpty ||
          _selectedLookingFor.isEmpty) {
        _showSnack('Please fill all required fields');
        return;
      }
    }

    if (_currentPage == 2) {
      if (_selectedInterests.length < 3) {
        _showSnack('Please select at least 3 interests');
        return;
      }
      _saveDemographicInfo();
      return;
    }

    setState(() => _currentPage++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipOnboarding() async {
    if (_isSkipping) return;

    _isSkipping = true;
    HapticFeedback.lightImpact();

    final hasUser = await _ensureCurrentUser();
    if (!hasUser) {
      _isSkipping = false;
      return;
    }
    if (!mounted) return;

    await _completeOnboardingAndGoHome();
  }

  Future<void> _completeOnboardingAndGoHome() async {
    if (_isCompletingOnboarding) return;

    _isCompletingOnboarding = true;
    final userBloc = context.read<UserBloc>();
    userBloc.add(CompleteOnboarding());

    try {
      final result = await userBloc.stream.firstWhere((state) {
        return state.status == UserStatus.success ||
            state.status == UserStatus.error;
      }).timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (result.status == UserStatus.error) {
        _showSnack(result.error ?? 'Failed to complete onboarding');
        _isCompletingOnboarding = false;
        _isSkipping = false;
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        NamedRoutes.homeScreen,
        (_) => false,
      );
    } on TimeoutException {
      if (!mounted) return;
      _showSnack('Connection timeout. Please try again.');
      _isCompletingOnboarding = false;
      _isSkipping = false;
    }
  }

  Future<void> _saveDemographicInfo() async {
    if (_isSavingDemographics) return;

    final hasUser = await _ensureCurrentUser();
    if (!hasUser) return;
    if (!mounted) return;

    _isSavingDemographics = true;

    context.read<ProfileBloc>().add(UpdateProfile(
          data: {
            'displayName': _displayNameController.text.isEmpty
                ? null
                : _displayNameController.text,
            'avatar': _selectedAvatarUrl,
            'coverImage': _selectedCoverUrl,
            'age': _calculatedAge,
            'gender': _selectedGender.isEmpty
                ? 'prefer not to say'
                : _selectedGender.toLowerCase(),
            'lookingFor': _selectedLookingFor.isEmpty
                ? 'friendship'
                : _selectedLookingFor.toLowerCase(),
            'bio': _bioController.text.isEmpty ? '' : _bioController.text,
            'location': _locationController.text.isEmpty
                ? ''
                : _locationController.text,
            'work': _workController.text.isEmpty ? '' : _workController.text,
            'education': _educationController.text.isEmpty
                ? ''
                : _educationController.text,
            'interests': _selectedInterests.isEmpty ? [] : _selectedInterests,
          },
        ));
  }

  Future<bool> _ensureCurrentUser() async {
    final userBloc = context.read<UserBloc>();

    if (userBloc.state.currentUser != null) {
      return true;
    }

    if (userBloc.state.status != UserStatus.loading) {
      userBloc.add(LoadCurrentUser());
    }

    try {
      final result = await userBloc.stream.firstWhere((state) {
        return state.status == UserStatus.success ||
            state.status == UserStatus.error;
      }).timeout(const Duration(seconds: 12));

      if (result.currentUser != null) {
        return true;
      }

      if (!mounted) return false;

      if (await _ensureProfileExists()) {
        return true;
      }

      if (!mounted) return false;

      _showSnack(
        result.error?.contains('User not found') == true
            ? 'Account setup is not complete yet. Please sign out and sign in again after the signup fix is applied.'
            : result.error?.contains('converting NULL to string') == true
                ? 'Account data needs a backend cleanup before this can finish.'
                : result.error ?? 'Unable to load your account.',
      );

      return false;
    } on TimeoutException {
      if (!mounted) return false;
      _showSnack('Connection timeout. Please try again.');
      return false;
    }
  }

  Future<bool> _ensureProfileExists() async {
    final profileBloc = context.read<ProfileBloc>();

    final currentProfile = profileBloc.state.myProfile;
    if (currentProfile != null && currentProfile.userId > 0) {
      return true;
    }

    if (profileBloc.state.status != ProfileStatus.loading) {
      profileBloc.add(LoadMyProfile());
    }

    try {
      final result = await profileBloc.stream.firstWhere((state) {
        return state.status == ProfileStatus.success ||
            state.status == ProfileStatus.error;
      }).timeout(const Duration(seconds: 12));

      final profile = result.myProfile;
      return profile != null && profile.userId > 0;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
                surface: AppColors.card,
                onSurface: AppColors.text,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateOfBirth = picked);
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Profile Picture',
                style: AppTheme.blackTextStyle
                    .copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarOptions.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() {
                    _selectedAvatarUrl = _avatarOptions[i];
                    Navigator.pop(context);
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: CachedNetworkImageProvider(_avatarOptions[i]),
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoverPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Cover Photo',
                style: AppTheme.blackTextStyle
                    .copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _coverOptions.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() {
                    _selectedCoverUrl = _coverOptions[i];
                    Navigator.pop(context);
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 160,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                          image: CachedNetworkImageProvider(_coverOptions[i]),
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
