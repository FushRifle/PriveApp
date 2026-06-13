class FeedPoll {
  final int id;
  final int postId;
  final String question;
  final List<FeedPollOption> options;
  final DateTime? expiresAt;
  final bool isMultipleChoice;
  final int totalVotes;
  final bool userVoted;
  final int? userVoteOptionId;
  final DateTime createdAt;

  const FeedPoll({
    required this.id,
    required this.postId,
    required this.question,
    required this.options,
    required this.expiresAt,
    required this.isMultipleChoice,
    required this.totalVotes,
    required this.userVoted,
    required this.userVoteOptionId,
    required this.createdAt,
  });

  factory FeedPoll.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'];
    final options = optionsJson is List
        ? optionsJson
            .whereType<Map>()
            .map((item) => FeedPollOption.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : const <FeedPollOption>[];

    return FeedPoll(
      id: _toInt(json['id']),
      postId: _toInt(json['postId'] ?? json['post_id']),
      question: json['question']?.toString().trim() ?? '',
      options: options,
      expiresAt: _parseDateTime(json['expiresAt'] ?? json['expires_at']),
      isMultipleChoice:
          json['isMultipleChoice'] == true || json['is_multiple_choice'] == true,
      totalVotes: _toInt(json['totalVotes'] ?? json['total_votes']),
      userVoted: json['userVoted'] == true || json['user_voted'] == true,
      userVoteOptionId: _toIntOrNull(
        json['userVoteOptionId'] ?? json['user_vote_option_id'],
      ),
      createdAt: _parseDateTime(
            json['createdAt'] ?? json['created_at'],
          ) ??
          DateTime.now(),
    );
  }

  bool get hasExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  FeedPoll copyWith({
    int? id,
    int? postId,
    String? question,
    List<FeedPollOption>? options,
    DateTime? expiresAt,
    bool? isMultipleChoice,
    int? totalVotes,
    bool? userVoted,
    int? userVoteOptionId,
    DateTime? createdAt,
  }) {
    return FeedPoll(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      question: question ?? this.question,
      options: options ?? this.options,
      expiresAt: expiresAt ?? this.expiresAt,
      isMultipleChoice: isMultipleChoice ?? this.isMultipleChoice,
      totalVotes: totalVotes ?? this.totalVotes,
      userVoted: userVoted ?? this.userVoted,
      userVoteOptionId: userVoteOptionId ?? this.userVoteOptionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FeedPollOption {
  final int id;
  final String text;
  final int votes;
  final double percentage;

  const FeedPollOption({
    required this.id,
    required this.text,
    required this.votes,
    required this.percentage,
  });

  factory FeedPollOption.fromJson(Map<String, dynamic> json) {
    return FeedPollOption(
      id: _toInt(json['id']),
      text: json['text']?.toString().trim() ?? '',
      votes: _toInt(json['votes'] ?? json['votes_count']),
      percentage: (json['percentage'] as num?)?.toDouble() ??
          _toDouble(json['percentage']),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
