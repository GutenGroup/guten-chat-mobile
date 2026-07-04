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

/// Mirrors `chat_conversation_participants.paid_status`.
enum ParticipantPaidStatus {
  free,
  pending,
  active,
  pastDue,
  canceled;

  static ParticipantPaidStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return ParticipantPaidStatus.pending;
      case 'active':
        return ParticipantPaidStatus.active;
      case 'past_due':
        return ParticipantPaidStatus.pastDue;
      case 'canceled':
        return ParticipantPaidStatus.canceled;
      case 'free':
      default:
        return ParticipantPaidStatus.free;
    }
  }

  String toJson() => switch (this) {
        ParticipantPaidStatus.free => 'free',
        ParticipantPaidStatus.pending => 'pending',
        ParticipantPaidStatus.active => 'active',
        ParticipantPaidStatus.pastDue => 'past_due',
        ParticipantPaidStatus.canceled => 'canceled',
      };
}

/// Mirrors `chat_conversation_participants`.
class Participant extends Equatable {
  const Participant({
    required this.conversationId,
    required this.profileId,
    required this.role,
    required this.joinedAt,
    this.paidStatus = ParticipantPaidStatus.free,
    this.invitedByProfileId,
    this.leftAt,
    this.lastReadAt,
    this.lastReadMessageId,
    this.isMuted = false,
  });

  final String conversationId;
  final String profileId;
  final ParticipantRole role;
  final ParticipantPaidStatus paidStatus;
  final String? invitedByProfileId;
  final DateTime? leftAt;
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
      paidStatus: ParticipantPaidStatus.fromJson(
        readJson<String>(json, 'paid_status', 'paidStatus'),
      ),
      invitedByProfileId: readJson<String>(
        json,
        'invited_by_profile_id',
        'invitedByProfileId',
      ),
      leftAt: readJson<dynamic>(json, 'left_at', 'leftAt') != null
          ? parseTimestamp(readJson<dynamic>(json, 'left_at', 'leftAt'))
          : null,
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
        'paid_status': paidStatus.toJson(),
        'invited_by_profile_id': invitedByProfileId,
        'left_at': leftAt?.toIso8601String(),
        'joined_at': joinedAt.toIso8601String(),
        'last_read_at': lastReadAt?.toIso8601String(),
        'last_read_message_id': lastReadMessageId,
        'is_muted': isMuted,
      };

  Participant copyWith({
    String? conversationId,
    String? profileId,
    ParticipantRole? role,
    ParticipantPaidStatus? paidStatus,
    String? invitedByProfileId,
    DateTime? leftAt,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    String? lastReadMessageId,
    bool? isMuted,
  }) {
    return Participant(
      conversationId: conversationId ?? this.conversationId,
      profileId: profileId ?? this.profileId,
      role: role ?? this.role,
      paidStatus: paidStatus ?? this.paidStatus,
      invitedByProfileId: invitedByProfileId ?? this.invitedByProfileId,
      leftAt: leftAt ?? this.leftAt,
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
        paidStatus,
        invitedByProfileId,
        leftAt,
        joinedAt,
        lastReadAt,
        lastReadMessageId,
        isMuted,
      ];
}
