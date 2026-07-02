import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

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

/// Mirrors `chat_conversations`.
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.type,
    this.title,
    this.imageUrl,
    this.createdByProfileId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.isPaid = false,
    this.joinPriceCents,
    this.joinCurrency,
    this.unreadCount = 0,
  });

  final String id;
  final ConversationType type;
  final String? title;
  final String? imageUrl;
  final String? createdByProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final bool isPaid;
  final int? joinPriceCents;
  final String? joinCurrency;
  final int unreadCount;

  bool get isGroup => type == ConversationType.group;
  bool get isDm => type == ConversationType.dm;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: requireString(json, 'id', 'id'),
      type: ConversationType.fromJson(
        readJson<String>(json, 'type', 'type'),
      ),
      title: readJson<String>(json, 'title', 'title'),
      imageUrl: readJson<String>(json, 'image_url', 'imageUrl'),
      createdByProfileId:
          readJson<String>(json, 'created_by_profile_id', 'createdByProfileId'),
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
      joinPriceCents:
          readInt(json, 'join_price_cents', 'joinPriceCents'),
      joinCurrency: readJson<String>(json, 'join_currency', 'joinCurrency'),
      unreadCount: readInt(json, 'unread_count', 'unreadCount') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'title': title,
        'image_url': imageUrl,
        'created_by_profile_id': createdByProfileId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'last_message_at': lastMessageAt?.toIso8601String(),
        'last_message_preview': lastMessagePreview,
        'is_paid': isPaid,
        'join_price_cents': joinPriceCents,
        'join_currency': joinCurrency,
        'unread_count': unreadCount,
      };

  Conversation copyWith({
    String? id,
    ConversationType? type,
    String? title,
    String? imageUrl,
    String? createdByProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    bool? isPaid,
    int? joinPriceCents,
    String? joinCurrency,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      createdByProfileId: createdByProfileId ?? this.createdByProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      isPaid: isPaid ?? this.isPaid,
      joinPriceCents: joinPriceCents ?? this.joinPriceCents,
      joinCurrency: joinCurrency ?? this.joinCurrency,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        imageUrl,
        createdByProfileId,
        createdAt,
        updatedAt,
        lastMessageAt,
        lastMessagePreview,
        isPaid,
        joinPriceCents,
        joinCurrency,
        unreadCount,
      ];
}
