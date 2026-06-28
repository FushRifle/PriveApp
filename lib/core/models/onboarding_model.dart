class OnboardingProfileRequest {
  final String name;
  final String bio;
  final int age;
  final String gender;
  final String country;
  final String countryCode;
  final String mobileNumber;
  final List<String> interests;
  final String? lookingFor;

  const OnboardingProfileRequest({
    required this.name,
    required this.bio,
    required this.age,
    required this.gender,
    required this.country,
    required this.countryCode,
    required this.mobileNumber,
    required this.interests,
    this.lookingFor,
  });

  Map<String, dynamic> toJson() => {
        'user': {
          'name': name,
          'age': age,
          'gender': gender,
          'country': country,
          'countryCode': countryCode,
          'mobileNumber': mobileNumber,
          'phone': '$countryCode$mobileNumber',
        },
        'profile': {
          'displayName': name,
          'bio': bio,
          'age': age,
          'gender': gender,
          'country': country,
          'interests': interests,
          if (lookingFor != null) 'lookingFor': lookingFor,
        },
      };
}
