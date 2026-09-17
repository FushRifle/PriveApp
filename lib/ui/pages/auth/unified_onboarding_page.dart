import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/models/onboarding_model.dart';
import 'package:clique/core/services/profile/profile_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/ui/pages/auth/auth_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnifiedOnboardingPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const UnifiedOnboardingPage({super.key, this.onComplete});

  @override
  State<UnifiedOnboardingPage> createState() => _UnifiedOnboardingPageState();
}

class _UnifiedOnboardingPageState extends State<UnifiedOnboardingPage> {
  static const _countries = <(String, String)>[
    ('Argentina', '+54'),
    ('Australia', '+61'),
    ('Brazil', '+55'),
    ('Canada', '+1'),
    ('China', '+86'),
    ('Egypt', '+20'),
    ('France', '+33'),
    ('Germany', '+49'),
    ('Ghana', '+233'),
    ('India', '+91'),
    ('Indonesia', '+62'),
    ('Ireland', '+353'),
    ('Italy', '+39'),
    ('Japan', '+81'),
    ('Kenya', '+254'),
    ('Mexico', '+52'),
    ('Netherlands', '+31'),
    ('New Zealand', '+64'),
    ('Nigeria', '+234'),
    ('Pakistan', '+92'),
    ('Portugal', '+351'),
    ('Singapore', '+65'),
    ('South Africa', '+27'),
    ('South Korea', '+82'),
    ('Spain', '+34'),
    ('Sweden', '+46'),
    ('Turkey', '+90'),
    ('United Arab Emirates', '+971'),
    ('United Kingdom', '+44'),
    ('United States', '+1'),
  ];
  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const _interestOptions = [
    'Art',
    'Business',
    'Cooking',
    'Design',
    'Fashion',
    'Fitness',
    'Gaming',
    'Movies',
    'Music',
    'Photography',
    'Reading',
    'Sports',
    'Technology',
    'Travel'
  ];

  final _pageController = PageController();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _age = TextEditingController();
  final _mobile = TextEditingController();
  final _service = ProfileService();
  final _interests = <String>{};
  int _step = 0;
  String? _gender;
  (String, String)? _country;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _name.dispose();
    _bio.dispose();
    _age.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'Make it yours',
              style: TextStyle(
                color: palette.text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _complete,
            child: Text(
              'Skip',
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'STEP ${_step + 1} OF 7',
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: (_step + 1) / 7,
                            minHeight: 5,
                            color: palette.primary,
                            backgroundColor: palette.border,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (value) => setState(() => _step = value),
                    children: [
                      _textStep(
                        'What should we call you?',
                        _name,
                        'Name (optional)',
                        icon: Icons.badge_outlined,
                      ),
                      _textStep(
                        'Tell people about you',
                        _bio,
                        'Bio (optional)',
                        maxLines: 5,
                        icon: Icons.notes_rounded,
                      ),
                      _textStep(
                        'How old are you?',
                        _age,
                        'Age (optional)',
                        numeric: true,
                        icon: Icons.cake_outlined,
                      ),
                      _choiceStep(
                        'How do you identify?',
                        _genders,
                        _gender,
                        (value) => setState(() => _gender = value),
                      ),
                      _countryStep(),
                      _phoneStep(),
                      _interestStep(),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: palette.background,
                    border: Border(
                      top: BorderSide(color: palette.border.withOpacity(0.65)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        OutlinedButton(
                          onPressed: _saving ? null : _previous,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(50, 50),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _saving ? null : (_step == 6 ? _complete : _next),
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _step == 6
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                          label:
                              Text(_step == 6 ? 'Finish profile' : 'Continue'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: palette.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shell(String title, Widget child) {
    final palette = AuthPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.text,
            fontSize: 27,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is optional—you can change it anytime.',
          style: TextStyle(color: palette.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 22),
        AuthSectionCard(child: child),
      ],
    );
  }

  Widget _textStep(String title, TextEditingController controller, String label,
      {int maxLines = 1, bool numeric = false, IconData? icon}) {
    return _shell(
      title,
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        textCapitalization:
            numeric ? TextCapitalization.none : TextCapitalization.sentences,
        decoration: authInputDecoration(
          context,
          label: label,
          icon: icon,
        ),
      ),
    );
  }

  Widget _choiceStep(String title, List<String> choices, String? selected,
      ValueChanged<String> onSelected) {
    final palette = AuthPalette.of(context);
    return _shell(
      title,
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: choices
            .map((value) => ChoiceChip(
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                  selectedColor: palette.primary.withOpacity(
                    palette.isDark ? 0.2 : 0.12,
                  ),
                  backgroundColor: palette.inputSurface,
                  side: BorderSide(
                    color: selected == value ? palette.primary : palette.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _countryStep() => _shell(
        'Where do you live?',
        Autocomplete<(String, String)>(
          displayStringForOption: (option) => option.$1,
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            return _countries.where((country) =>
                query.isEmpty || country.$1.toLowerCase().contains(query));
          },
          onSelected: (value) => setState(() => _country = value),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
              TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: authInputDecoration(
              context,
              label: 'Search countries',
              icon: Icons.search_rounded,
            ),
          ),
        ),
      );

  Widget _phoneStep() => _shell(
        'What is your mobile number?',
        Row(children: [
          SizedBox(
            width: 112,
            child: DropdownButtonFormField<(String, String)>(
              value: _country,
              isExpanded: true,
              decoration: authInputDecoration(context, label: 'Code'),
              items: _countries
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.$2, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (country) => setState(() => _country = country),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: authInputDecoration(
                context,
                label: 'Mobile number',
                icon: Icons.phone_outlined,
              ),
            ),
          ),
        ]),
      );

  Widget _interestStep() => _shell(
        'What are you interested in?',
        Builder(builder: (context) {
          final palette = AuthPalette.of(context);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestOptions
                .map((interest) => FilterChip(
                      label: Text(interest),
                      selected: _interests.contains(interest),
                      selectedColor: palette.secondary.withOpacity(
                        palette.isDark ? 0.2 : 0.12,
                      ),
                      backgroundColor: palette.inputSurface,
                      side: BorderSide(
                        color: _interests.contains(interest)
                            ? palette.secondary
                            : palette.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (selected) => setState(() => selected
                          ? _interests.add(interest)
                          : _interests.remove(interest)),
                    ))
                .toList(),
          );
        }),
      );

  void _next() {
    final age = int.tryParse(_age.text.trim());
    String? error;
    if (_step == 0 &&
        _name.text.trim().isNotEmpty &&
        _name.text.trim().length < 2) {
      error = 'Name must be at least 2 characters, or leave it blank';
    }
    if (_step == 2 &&
        _age.text.trim().isNotEmpty &&
        (age == null || age < 18 || age > 120)) {
      error = 'Enter a valid age (18+), or leave it blank';
    }
    if (_step == 5 &&
        _mobile.text.trim().isNotEmpty &&
        _mobile.text.trim().length < 6) {
      error = 'Enter a valid mobile number, or leave it blank';
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _pageController.nextPage(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  void _previous() => _pageController.previousPage(
      duration: const Duration(milliseconds: 220), curve: Curves.easeOut);

  Future<void> _complete() async {
    setState(() => _saving = true);
    Object? saveError;
    try {
      await _service.completeOnboarding(OnboardingProfileRequest(
        name: _emptyAsNull(_name.text),
        bio: _emptyAsNull(_bio.text),
        age: int.tryParse(_age.text.trim()),
        gender: _gender,
        country: _country?.$1,
        countryCode: _country?.$2,
        mobileNumber: _emptyAsNull(_mobile.text),
        interests: _interests.toList(),
      ));
    } catch (error) {
      saveError = error;
    }

    // Registration must complete even if optional profile data could not save.
    try {
      await UserService().markDemographicsSeen();
    } catch (_) {}

    if (!mounted) return;
    context.read<ProfileBloc>().add(RefreshMyProfile());
    context.read<UserBloc>().add(RefreshCurrentUser());
    if (saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. You can finish your profile later.'),
        ),
      );
    }
    setState(() => _saving = false);
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, NamedRoutes.homeScreen, (_) => false);
    }
  }

  String? _emptyAsNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
