import 'package:clique/bloc/profile/profile_bloc.dart';

class ProfileView {
  final int id;
  final int userId;
  final String? displayName;
  final String? username;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final List<String> photos;
  final List<String> interests;
  final int age;
  final String? gender;
  final String? lookingFor;
  final String? location;
  final String? work;
  final String? education;

  const ProfileView({
    required this.id,
    required this.userId,
    this.displayName,
    this.username,
    this.bio,
    this.avatar,
    this.coverImage,
    this.photos = const [],
    this.interests = const [],
    this.age = 0,
    this.gender,
    this.lookingFor,
    this.location,
    this.work,
    this.education,
  });

  static ProfileView? fromSources({
    Map<String, dynamic>? user,
    Profile? profile,
  }) {
    if (user == null && profile == null) return null;

    final id = _readInt(user?['id'] ?? user?['userId'] ?? user?['user_id']);
    final userId = _readInt(user?['userId'] ?? user?['user_id'] ?? user?['id']);
    final profileUserId = profile?.userId ?? 0;
    final name = _readName(user) ?? _readString(profile?.displayName);
    final username =
        _readString(user?['username']) ?? _readString(profile?.displayName);

    return ProfileView(
      id: id != 0 ? id : profile?.id ?? 0,
      userId: profileUserId != 0 ? profileUserId : userId,
      displayName: name,
      username: username,
      bio: _readString(profile?.bio) ?? _readString(user?['bio']),
      avatar: _readString(user?['avatar']) ?? _readString(profile?.avatar),
      coverImage: _readString(
              user?['coverImage'] ?? user?['cover_image'] ?? user?['cover']) ??
          _readString(profile?.coverImage),
      photos: profile?.photos.isNotEmpty == true
          ? profile!.photos
          : _readStringList(user?['photos']),
      interests: profile?.interests.isNotEmpty == true
          ? profile!.interests
          : _readStringList(user?['interests'] ?? user?['languages']),
      age: profile?.age != 0 ? profile?.age ?? 0 : _readInt(user?['age']),
      gender: _readString(profile?.gender) ?? _readString(user?['gender']),
      lookingFor: _readString(profile?.lookingFor) ??
          _readString(user?['lookingFor'] ?? user?['looking_for']),
      location:
          _readString(profile?.location) ?? _readString(user?['location']),
      work: _readString(profile?.work) ?? _readString(user?['work']),
      education:
          _readString(profile?.education) ?? _readString(user?['education']),
    );
  }

  Map<String, dynamic> toProfileUpdateData() {
    return {
      'displayName': displayName,
      'bio': bio,
      'avatar': avatar,
      'coverImage': coverImage,
      'age': age > 0 ? age : null,
      'gender': gender,
      'lookingFor': lookingFor,
      'location': location,
      'work': work,
      'education': education,
      'interests': interests,
    };
  }

  Map<String, dynamic> toUserUpdateData() {
    return {
      'name': displayName,
      'bio': bio,
      'avatar': avatar,
      'coverImage': coverImage,
      'age': age > 0 ? age : null,
      'location': location,
      'work': work,
      'education': education,
      'languages': interests,
    };
  }

  String get displayNameOrDefault => displayName ?? 'User';

  String get ageText => age > 0 ? '$age years old' : 'Age not specified';

  bool get isOfficialAccount {
    final name = (displayName ?? '').trim().toLowerCase();
    final handle = (username ?? '').trim().toLowerCase();

    return name == 'clique official' ||
        handle == 'clique_official' ||
        handle == 'official' ||
        handle == 'cliqueofficial';
  }

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty && item != 'null')
          .toList();
    }
    return const [];
  }

  static String? _readName(Map<String, dynamic>? user) {
    if (user == null) return null;

    final name = _readString(user['name'] ?? user['displayName']);
    if (name != null) return name;

    final firstName = _readString(user['firstName'] ?? user['first_name']);
    final lastName = _readString(user['lastName'] ?? user['last_name']);
    final fullName = [
      firstName,
      lastName,
    ].whereType<String>().join(' ').trim();
    if (fullName.isNotEmpty) return fullName;

    return _readString(user['username'] ?? user['email']);
  }
}
