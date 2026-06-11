import 'package:equatable/equatable.dart';

class Call extends Equatable {
  final int id;
  final int callerId;
  final int receiverId;
  final String roomId;
  final String callType; // voice, video
  final String status; // ringing, accepted, rejected, ended, missed
  final DateTime startedAt;
  final DateTime? acceptedAt;
  final DateTime? endedAt;
  final int duration; // seconds

  const Call({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.roomId,
    required this.callType,
    required this.status,
    required this.startedAt,
    this.acceptedAt,
    this.endedAt,
    this.duration = 0,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as int,
      callerId: json['callerId'] as int,
      receiverId: json['receiverId'] as int,
      roomId: json['roomId'] as String,
      callType: json['callType'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      acceptedAt: json['acceptedAt'] != null 
          ? DateTime.parse(json['acceptedAt'] as String) 
          : null,
      endedAt: json['endedAt'] != null 
          ? DateTime.parse(json['endedAt'] as String) 
          : null,
      duration: json['duration'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'roomId': roomId,
      'callType': callType,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'duration': duration,
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, callerId, receiverId, status];
}

class CallWithParticipants {
  final Call call;
  final UserInfo caller;
  final UserInfo receiver;
  final List<UserInfo> participants;

  const CallWithParticipants({
    required this.call,
    required this.caller,
    required this.receiver,
    this.participants = const [],
  });

  factory CallWithParticipants.fromJson(Map<String, dynamic> json) {
    return CallWithParticipants(
      call: Call.fromJson(json['call']),
      caller: UserInfo.fromJson(json['caller']),
      receiver: UserInfo.fromJson(json['receiver']),
      participants: (json['participants'] as List?)
          ?.map((p) => UserInfo.fromJson(p))
          .toList() ?? [],
    );
  }
}

class UserInfo {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final bool verified;

  const UserInfo({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    this.verified = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
    );
  }
}

class CallHistory {
  final int id;
  final int userId;
  final int callId;
  final int otherUserId;
  final String callType;
  final String direction;
  final String status;
  final int duration;
  final DateTime startedAt;
  final DateTime endedAt;

  const CallHistory({
    required this.id,
    required this.userId,
    required this.callId,
    required this.otherUserId,
    required this.callType,
    required this.direction,
    required this.status,
    required this.duration,
    required this.startedAt,
    required this.endedAt,
  });

  factory CallHistory.fromJson(Map<String, dynamic> json) {
    return CallHistory(
      id: json['id'] as int,
      userId: json['userId'] as int,
      callId: json['callId'] as int,
      otherUserId: json['otherUserId'] as int,
      callType: json['callType'] as String,
      direction: json['direction'] as String,
      status: json['status'] as String,
      duration: json['duration'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
    );
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class IncomingCallNotification {
  final int callId;
  final UserInfo caller;
  final String callType;
  final String roomId;

  const IncomingCallNotification({
    required this.callId,
    required this.caller,
    required this.callType,
    required this.roomId,
  });

  factory IncomingCallNotification.fromJson(Map<String, dynamic> json) {
    return IncomingCallNotification(
      callId: json['callId'] as int,
      caller: UserInfo.fromJson(json['caller']),
      callType: json['callType'] as String,
      roomId: json['roomId'] as String,
    );
  }
}