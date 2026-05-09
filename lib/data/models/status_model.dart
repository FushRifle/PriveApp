class StatusModel {
  final int id;
  final int userId;
  final String name;
  final String imgProfile;
  final String statusImage;
  final String statusImageHash;
  final String time;
  final bool isViewed;
  final int viewCount;
  final String? statusText;
  final String? backgroundColor;
  final String? textAlign;
  final double? fontSize;
  final int statusCount;
  final String content;

  const StatusModel({
    this.id = 0,
    this.userId = 0,
    required this.name,
    required this.imgProfile,
    required this.statusImage,
    this.statusImageHash = '',
    required this.time,
    this.isViewed = false,
    this.viewCount = 0,
    this.statusText,
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
    this.statusCount = 0,
    this.content = '',
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final attachments = json['attachments'];

    // Get text from either 'content' or 'statusText' field
    final textContent = json['content'] ?? json['statusText'];
    final hasText = textContent != null && textContent.toString().isNotEmpty;

    String statusImage = '';

    // Only get image if there's no text content
    if (!hasText && attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        statusImage = (first['url'] ?? first['uri'] ?? '').toString();
      } else if (first is String) {
        statusImage = first;
      }
    }

    // If still no image, check direct fields
    if (statusImage.isEmpty && !hasText) {
      statusImage = (json['statusImage'] ??
              json['status_image'] ??
              json['image'] ??
              json['imageUrl'] ??
              json['image_url'] ??
              '')
          .toString();
    }

    // Parse background color (for text stories)
    String? backgroundColor = json['backgroundColor'] ??
        json['background_color'] ??
        json['bgColor'] ??
        json['bg_color'];

    // Default background color for text stories if not provided
    if (hasText && (backgroundColor == null || backgroundColor.isEmpty)) {
      backgroundColor = '#1D1B20'; // Dark gray default
    }

    // Parse text alignment
    String? textAlign =
        json['textAlign'] ?? json['text_align'] ?? json['alignment'];

    // Parse font size
    double? fontSize;
    if (json['fontSize'] != null) {
      fontSize = _toDouble(json['fontSize']);
    } else if (json['font_size'] != null) {
      fontSize = _toDouble(json['font_size']);
    }

    return StatusModel(
      id: _toInt(json['id']),
      userId: _toInt(json['userId'] ?? json['user_id'] ?? user['id']),
      name: (user['name'] ??
              user['username'] ??
              json['name'] ??
              json['username'] ??
              'User')
          .toString(),
      imgProfile: (user['avatar'] ??
              user['avatarUrl'] ??
              user['avatar_url'] ??
              json['imgProfile'] ??
              json['avatar'] ??
              '')
          .toString(),
      statusImage: statusImage,
      statusImageHash:
          (json['statusImageHash'] ?? json['status_image_hash'] ?? '')
              .toString(),
      time: _formatTime(
          json['time'] ?? json['createdAt'] ?? json['created_at'] ?? ''),
      isViewed: json['isViewed'] == true ||
          json['isSeen'] == true ||
          json['is_seen'] == true,
      viewCount: _toInt(json['viewCount'] ?? json['view_count']),
      statusText: textContent?.toString(),
      backgroundColor: backgroundColor,
      textAlign: textAlign,
      fontSize: fontSize,
      content: textContent?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'imgProfile': imgProfile,
        'statusImage': statusImage,
        'statusImageHash': statusImageHash,
        'time': time,
        'isViewed': isViewed,
        'viewCount': viewCount,
        'statusText': statusText,
        'backgroundColor': backgroundColor,
        'textAlign': textAlign,
        'fontSize': fontSize,
        'content': content,
      };

  // Helper to check if this is a text-only story
  bool get isTextOnly =>
      statusText != null && statusText!.isNotEmpty && statusImage.isEmpty;

  // Helper to check if this has an image
  bool get hasImage => statusImage.isNotEmpty;

  // Helper to get display text
  String get displayText => statusText ?? content;

  // Helper to get background color with default
  String get effectiveBackgroundColor {
    if (backgroundColor != null && backgroundColor!.isNotEmpty) {
      return backgroundColor!;
    }
    return isTextOnly ? '#1D1B20' : '#000000';
  }

  // Helper to get text alignment with default
  String get effectiveTextAlign => textAlign ?? 'center';

  // Helper to get font size with default
  double get effectiveFontSize => fontSize ?? 24.0;
}

// Helper functions
double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 24.0;
  return 24.0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

String _formatTime(dynamic timeValue) {
  if (timeValue == null) return '';

  try {
    if (timeValue is String) {
      // Check if it's already a formatted time like "15m ago"
      if (timeValue.contains('ago') ||
          timeValue.contains('min') ||
          timeValue.contains('hour') ||
          timeValue.contains('day')) {
        return timeValue;
      }
      // Try to parse as DateTime
      final dateTime = DateTime.parse(timeValue);
      return _timeAgo(dateTime);
    }

    if (timeValue is DateTime) {
      return _timeAgo(timeValue);
    }

    return timeValue.toString();
  } catch (e) {
    return timeValue.toString();
  }
}

String _timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 7) {
    return '${difference.inDays ~/ 7}w ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}
