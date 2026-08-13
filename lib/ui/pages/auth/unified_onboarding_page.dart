import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/models/onboarding_model.dart';
import 'package:clique/core/services/profile/profile_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/core/router/named_routes.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Optional profile details',
            style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _complete,
            child: const Text('Skip for now'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 7),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _step = value),
                children: [
                  _textStep(
                      'What should we call you?', _name, 'Name (optional)'),
                  _textStep('Tell people about you', _bio, 'Bio (optional)',
                      maxLines: 5),
                  _textStep('How old are you?', _age, 'Age (optional)',
                      numeric: true),
                  _choiceStep('How do you identify?', _genders, _gender,
                      (value) => setState(() => _gender = value)),
                  _countryStep(),
                  _phoneStep(),
                  _interestStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      tooltip: 'Previous step',
                      onPressed: _saving ? null : _previous,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed:
                        _saving ? null : (_step == 6 ? _complete : _next),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_step == 6
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded),
                    label: Text(_step == 6 ? 'Finish' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shell(String title, Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 28),
          child,
        ],
      );

  Widget _textStep(String title, TextEditingController controller, String label,
      {int maxLines = 1, bool numeric = false}) {
    return _shell(
      title,
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        textCapitalization:
            numeric ? TextCapitalization.none : TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _choiceStep(String title, List<String> choices, String? selected,
      ValueChanged<String> onSelected) {
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
            decoration: const InputDecoration(
              labelText: 'Search countries',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
      );

  Widget _phoneStep() => _shell(
        'What is your mobile number?',
        Row(children: [
          DropdownButton<String>(
            value: _country?.$2,
            hint: const Text('Code'),
            items: _countries
                .map((item) => DropdownMenuItem(
                      value: item.$2,
                      child: Text('${item.$1} ${item.$2}',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (code) {
              final country = _countries.firstWhere((item) => item.$2 == code);
              setState(() => _country = country);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
              child: TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number'),
          )),
        ]),
      );

  Widget _interestStep() => _shell(
        'What are you interested in?',
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions
              .map((interest) => FilterChip(
                    label: Text(interest),
                    selected: _interests.contains(interest),
                    onSelected: (selected) => setState(() => selected
                        ? _interests.add(interest)
                        : _interests.remove(interest)),
                  ))
              .toList(),
        ),
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
