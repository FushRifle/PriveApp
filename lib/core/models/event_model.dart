class EventModel {
  final int id;
  final int hostId;
  final String title;
  final String slug;
  final String description;
  final String category;
  final String location;
  final String imageUrl;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isPrivate;
  final int goingCount;
  final int interestedCount;
  final String rsvpStatus;
  final bool isGoing;
  final bool isInterested;
  final EventUserModel? host;

  const EventModel({
    required this.id,
    required this.hostId,
    required this.title,
    required this.slug,
    required this.description,
    required this.category,
    required this.location,
    required this.imageUrl,
    required this.startsAt,
    required this.endsAt,
    required this.isPrivate,
    required this.goingCount,
    required this.interestedCount,
    required this.rsvpStatus,
    required this.isGoing,
    required this.isInterested,
    required this.host,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final rsvpStatus = _readString(json['rsvpStatus'] ?? json['rsvp_status']);
    final startsAt =
        DateTime.tryParse(_readString(json['startsAt'] ?? json['starts_at'])) ??
            DateTime.now();
    final endsAtText = _readString(json['endsAt'] ?? json['ends_at']);

    return EventModel(
      id: _readInt(json['id']),
      hostId: _readInt(json['hostId'] ?? json['host_id']),
      title: _readString(json['title'], fallback: 'Event'),
      slug: _readString(json['slug']),
      description: _readString(json['description']),
      category: _readString(json['category']),
      location: _readString(json['location']),
      imageUrl: _readString(json['imageUrl'] ?? json['image_url']),
      startsAt: startsAt,
      endsAt: endsAtText.isEmpty ? null : DateTime.tryParse(endsAtText),
      isPrivate: json['isPrivate'] == true || json['is_private'] == true,
      goingCount: _readInt(json['goingCount'] ?? json['going_count']),
      interestedCount:
          _readInt(json['interestedCount'] ?? json['interested_count']),
      rsvpStatus: rsvpStatus,
      isGoing: rsvpStatus == 'going',
      isInterested: rsvpStatus == 'interested',
      host: json['host'] is Map
          ? EventUserModel.fromJson(Map<String, dynamic>.from(json['host']))
          : null,
    );
  }

  EventModel copyWith({
    int? goingCount,
    int? interestedCount,
    String? rsvpStatus,
  }) {
    final nextStatus = rsvpStatus ?? this.rsvpStatus;
    return EventModel(
      id: id,
      hostId: hostId,
      title: title,
      slug: slug,
      description: description,
      category: category,
      location: location,
      imageUrl: imageUrl,
      startsAt: startsAt,
      endsAt: endsAt,
      isPrivate: isPrivate,
      goingCount: goingCount ?? this.goingCount,
      interestedCount: interestedCount ?? this.interestedCount,
      rsvpStatus: nextStatus,
      isGoing: nextStatus == 'going',
      isInterested: nextStatus == 'interested',
      host: host,
    );
  }
}

class EventAttendeeModel {
  final EventUserModel user;
  final String status;
  final DateTime? joinedAt;

  const EventAttendeeModel({
    required this.user,
    required this.status,
    required this.joinedAt,
  });

  factory EventAttendeeModel.fromJson(Map<String, dynamic> json) {
    return EventAttendeeModel(
      user: EventUserModel.fromJson(
        json['user'] is Map
            ? Map<String, dynamic>.from(json['user'])
            : Map<String, dynamic>.from(json),
      ),
      status: _readString(json['status'], fallback: 'going'),
      joinedAt:
          DateTime.tryParse(_readString(json['joinedAt'] ?? json['joined_at'])),
    );
  }
}

class EventUserModel {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final bool verified;

  const EventUserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.verified,
  });

  factory EventUserModel.fromJson(Map<String, dynamic> json) {
    return EventUserModel(
      id: _readInt(json['id']),
      name: _readString(json['name'], fallback: 'User'),
      username: _readString(json['username']),
      avatar: _readString(json['avatar']),
      verified: json['verified'] == true || json['isVerified'] == true,
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}
