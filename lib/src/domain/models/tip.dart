import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

/// Mirrors `chat_tips`.
class Tip extends Equatable {
  const Tip({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    required this.recipientProfileId,
    required this.amountCents,
    required this.currency,
    required this.createdAt,
    this.messageId,
    this.note,
  });

  final String id;
  final String conversationId;
  final String senderProfileId;
  final String recipientProfileId;
  final int amountCents;
  final String currency;
  final DateTime createdAt;
  final String? messageId;
  final String? note;

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: requireString(json, 'id', 'id'),
      conversationId:
          requireString(json, 'conversation_id', 'conversationId'),
      // Live schema columns are `from_profile_id` / `to_profile_id`; the
      // legacy names accepted for older payloads + toJson round-trip.
      senderProfileId: readJson<String>(json, 'from_profile_id',
              'fromProfileId') ??
          requireString(json, 'sender_profile_id', 'senderProfileId'),
      recipientProfileId: readJson<String>(json, 'to_profile_id',
              'toProfileId') ??
          requireString(json, 'recipient_profile_id', 'recipientProfileId'),
      amountCents: readInt(json, 'amount_cents', 'amountCents') ?? 0,
      currency: readJson<String>(json, 'currency', 'currency') ?? 'USD',
      createdAt: parseTimestamp(
        readJson<dynamic>(json, 'created_at', 'createdAt'),
      ),
      messageId: readJson<String>(json, 'message_id', 'messageId'),
      note: readJson<String>(json, 'note', 'note'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'from_profile_id': senderProfileId,
        'sender_profile_id': senderProfileId,
        'to_profile_id': recipientProfileId,
        'recipient_profile_id': recipientProfileId,
        'amount_cents': amountCents,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
        'message_id': messageId,
        'note': note,
      };

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderProfileId,
        recipientProfileId,
        amountCents,
        currency,
        createdAt,
        messageId,
        note,
      ];
}
