import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';
import 'invite_attachment.dart';
import 'participant.dart';

enum ConversationType {
  dm,
  group;

  static ConversationType fromJson(String? value) {
    switch (value) {
      case 'group':
        return ConversationType.group;
      case 'dm':
      default:
        return ConversationType.dm;
    }
  }

  String toJson() => name;
}

/// Billing interval for paid communities (`chat_conversations.billing_interval`).
enum BillingInterval {
  oneTime('one_time'),
  monthly('monthly'),
  quarterly('quarterly'),
  annual('annual');

  const BillingInterval(this.value);

  final String value;

  static BillingInterval? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final interval in BillingInterval.values) {
      if (interval.value == raw) {
        return interval;
      }
    }
    return null;
  }

  String get joinLabel => switch (this) {
        BillingInterval.oneTime => 'one-time',
        BillingInterval.monthly => 'month',
        BillingInterval.quarterly => 'quarter',
        BillingInterval.annual => 'year',
      };

  String get priceSuffix => switch (this) {
        BillingInterval.oneTime => '',
        BillingInterval.monthly => '/mo',
        BillingInterval.quarterly => '/quarter',
        BillingInterval.annual => '/yr',
      };
}

/// Formats a paid-community price for display (always USD).
String formatCommunityPrice(int? priceCents, BillingInterval? billingInterval) {
  if (priceCents == null) {
    return 'Paid';
  }
  final hasCents = priceCents % 100 != 0;
  final dollars = (priceCents / 100).toStringAsFixed(hasCents ? 2 : 0);
  final suffix = billingInterval?.priceSuffix ?? '/mo';
  return '\$$dollars$suffix';
}

/// Mirrors `chat_conversations`.
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.imageUrl,
    this.createdByProfileId,
    this.ownerProfileId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.isPaid = false,
    this.priceCents,
    this.billingInterval,
    this.inviteMessage,
    this.inviteAttachment,
    this.myPaidStatus,
    this.unreadCount = 0,
  });

  final String id;
  final ConversationType type;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? createdByProfileId;
  final String? ownerProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final bool isPaid;
  final int? priceCents;
  final BillingInterval? billingInterval;
  final String? inviteMessage;
  final InviteAttachment? inviteAttachment;
  final ParticipantPaidStatus? myPaidStatus;
  final int unreadCount;

  bool get isGroup => type == ConversationType.group;
  bool get isDm => type == ConversationType.dm;

  bool get isPaidInvitePending =>
      isPaid && myPaidStatus == ParticipantPaidStatus.pending;

  bool get isPaidGateActive =>
      isPaid && myPaidStatus != ParticipantPaidStatus.active;

  String get formattedPrice => formatCommunityPrice(priceCents, billingInterval);

  /// Price label for the join gate button (`$10/month`, `$50/one-time`, …).
  String get joinPriceLabel {
    if (priceCents == null) {
      return 'Paid';
    }
    final hasCents = priceCents! % 100 != 0;
    final dollars = (priceCents! / 100).toStringAsFixed(hasCents ? 2 : 0);
    final interval = billingInterval?.joinLabel ?? 'month';
    return '\$$dollars/$interval';
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    String? currentProfileId,
  }) {
    InviteAttachment? inviteAttachment;
    final attachmentPath = readJson<String>(
      json,
      'invite_attachment_path',
      'inviteAttachmentPath',
    );
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      inviteAttachment = InviteAttachment.fromConversationJson(json);
    }

    return Conversation(
      id: requireString(json, 'id', 'id'),
      type: ConversationType.fromJson(
        readJson<String>(json, 'type', 'type'),
      ),
      title: readJson<String>(json, 'title', 'title'),
      description: readJson<String>(json, 'description', 'description'),
      imageUrl: readJson<String>(json, 'image_url', 'imageUrl'),
      createdByProfileId:
          readJson<String>(json, 'created_by_profile_id', 'createdByProfileId'),
      ownerProfileId:
          readJson<String>(json, 'owner_profile_id', 'ownerProfileId'),
      createdAt: parseTimestamp(
        readJson<dynamic>(json, 'created_at', 'createdAt'),
      ),
      updatedAt: parseTimestamp(
        readJson<dynamic>(json, 'updated_at', 'updatedAt'),
      ),
      lastMessageAt: readJson<dynamic>(json, 'last_message_at', 'lastMessageAt') !=
              null
          ? parseTimestamp(
              readJson<dynamic>(json, 'last_message_at', 'lastMessageAt'),
            )
          : null,
      lastMessagePreview:
          readJson<String>(json, 'last_message_preview', 'lastMessagePreview'),
      isPaid: readJson<bool>(json, 'is_paid', 'isPaid') ?? false,
      priceCents: readInt(json, 'price_cents', 'priceCents'),
      billingInterval: BillingInterval.fromJson(
        readJson<String>(json, 'billing_interval', 'billingInterval'),
      ),
      inviteMessage: readJson<String>(json, 'invite_message', 'inviteMessage'),
      inviteAttachment: inviteAttachment,
      myPaidStatus: _parseMyPaidStatus(json, currentProfileId),
      unreadCount: readInt(json, 'unread_count', 'unreadCount') ?? 0,
    );
  }

  static ParticipantPaidStatus? _parseMyPaidStatus(
    Map<String, dynamic> json,
    String? currentProfileId,
  ) {
    if (currentProfileId == null) {
      return null;
    }
    final nested = json['chat_conversation_participants'];
    if (nested is! List) {
      return null;
    }
    for (final item in nested) {
      if (item is! Map) {
        continue;
      }
      final row = Map<String, dynamic>.from(item);
      final profileId = readJson<String>(row, 'profile_id', 'profileId');
      if (profileId == currentProfileId) {
        return ParticipantPaidStatus.fromJson(
          readJson<String>(row, 'paid_status', 'paidStatus'),
        );
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'created_by_profile_id': createdByProfileId,
        'owner_profile_id': ownerProfileId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'last_message_at': lastMessageAt?.toIso8601String(),
        'last_message_preview': lastMessagePreview,
        'is_paid': isPaid,
        'price_cents': priceCents,
        'billing_interval': billingInterval?.value,
        'invite_message': inviteMessage,
        'unread_count': unreadCount,
      };

  Conversation copyWith({
    String? id,
    ConversationType? type,
    String? title,
    String? description,
    String? imageUrl,
    String? createdByProfileId,
    String? ownerProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    bool? isPaid,
    int? priceCents,
    BillingInterval? billingInterval,
    String? inviteMessage,
    InviteAttachment? inviteAttachment,
    ParticipantPaidStatus? myPaidStatus,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdByProfileId: createdByProfileId ?? this.createdByProfileId,
      ownerProfileId: ownerProfileId ?? this.ownerProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      isPaid: isPaid ?? this.isPaid,
      priceCents: priceCents ?? this.priceCents,
      billingInterval: billingInterval ?? this.billingInterval,
      inviteMessage: inviteMessage ?? this.inviteMessage,
      inviteAttachment: inviteAttachment ?? this.inviteAttachment,
      myPaidStatus: myPaidStatus ?? this.myPaidStatus,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        imageUrl,
        createdByProfileId,
        ownerProfileId,
        createdAt,
        updatedAt,
        lastMessageAt,
        lastMessagePreview,
        isPaid,
        priceCents,
        billingInterval,
        inviteMessage,
        inviteAttachment,
        myPaidStatus,
        unreadCount,
      ];
}
