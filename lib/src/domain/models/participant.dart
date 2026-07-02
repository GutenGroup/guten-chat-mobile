import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

enum ParticipantRole {
  owner,
  admin,
  moderator,
  member;

  static ParticipantRole fromJson(String? value) {
    switch (value) {
      case 'owner':
        return ParticipantRole.owner;
      case 'admin':
        return ParticipantRole.admin;
      case 'moderator':
        return ParticipantRole.moderator;
      case 'member':
      default:
        return ParticipantRole.member;
    }
  }

  String toJson() => name;

  bool get canModerate =>
      this == ParticipantRole.owner ||
      this == ParticipantRole.admin ||
      this == ParticipantRole.moderator;
}

/// Mirrors `chat_conversation_participants`.
class Participant extends Equatable {
  const Participant({
    required this.conversationId,
    required this.profileId,
    required this.role,
    required this.joinedAt,
    this.lastReadAt,
    this.lastReadMessageId,
    this.isMuted = false,
  });

  final String conversationId;
  final String profileId;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final String? lastReadMessageId;
  final bool isMuted;

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      conversationId:
          requireString(json, 'conversation_id', 'conversationId'),
      profileId: requireString(json, 'profile_id', 'profileId'),
      role: ParticipantRole.fromJson(
        readJson<String>(json, 'role', 'role'),
      ),
      joinedAt: parseTimestamp(
        readJson<dynamic>(json, 'joined_at', 'joinedAt'),
      ),
      lastReadAt: readJson<dynamic>(json, 'last_read_at', 'lastReadAt') != null
          ? parseTimestamp(
              readJson<dynamic>(json, 'last_read_at', 'lastReadAt'),
            )
          : null,
      lastReadMessageId:
          readJson<String>(json, 'last_read_message_id', 'lastReadMessageId'),
      isMuted: readJson<bool>(json, 'is_muted', 'isMuted') ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'profile_id': profileId,
        'role': role.toJson(),
        'joined_at': joinedAt.toIso8601String(),
        'last_read_at': lastReadAt?.toIso8601String(),
        'last_read_message_id': lastReadMessageId,
        'is_muted': isMuted,
      };

  Participant copyWith({
    String? conversationId,
    String? profileId,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    String? lastReadMessageId,
    bool? isMuted,
  }) {
    return Participant(
      conversationId: conversationId ?? this.conversationId,
      profileId: profileId ?? this.profileId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  List<Object?> get props => [
        conversationId,
        profileId,
        role,
        joinedAt,
        lastReadAt,
        lastReadMessageId,
        isMuted,
      ];
}
