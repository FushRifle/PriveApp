class OnboardingProfileRequest {
  final String? name;
  final String? bio;
  final int? age;
  final String? gender;
  final String? country;
  final String? countryCode;
  final String? mobileNumber;
  final List<String> interests;
  final String? lookingFor;

  const OnboardingProfileRequest({
    this.name,
    this.bio,
    this.age,
    this.gender,
    this.country,
    this.countryCode,
    this.mobileNumber,
    this.interests = const [],
    this.lookingFor,
  });

  Map<String, dynamic> toJson() => {
        'user': {
          if (name != null && name!.isNotEmpty) 'name': name,
          if (age != null) 'age': age,
          if (gender != null && gender!.isNotEmpty) 'gender': gender,
          if (country != null && country!.isNotEmpty) 'country': country,
          if (countryCode != null && countryCode!.isNotEmpty)
            'countryCode': countryCode,
          if (mobileNumber != null && mobileNumber!.isNotEmpty)
            'mobileNumber': mobileNumber,
          if (countryCode != null &&
              mobileNumber != null &&
              mobileNumber!.isNotEmpty)
            'phone': '$countryCode$mobileNumber',
        },
        'profile': {
          if (name != null && name!.isNotEmpty) 'displayName': name,
          if (bio != null && bio!.isNotEmpty) 'bio': bio,
          if (age != null) 'age': age,
          if (gender != null && gender!.isNotEmpty) 'gender': gender,
          if (country != null && country!.isNotEmpty) 'country': country,
          if (interests.isNotEmpty) 'interests': interests,
          if (lookingFor != null) 'lookingFor': lookingFor,
        },
      };
}
