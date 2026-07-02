import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

enum PaymentRequestStatus {
  pending,
  paid,
  cancelled,
  expired;

  static PaymentRequestStatus fromJson(String? value) {
    switch (value) {
      case 'paid':
        return PaymentRequestStatus.paid;
      case 'cancelled':
        return PaymentRequestStatus.cancelled;
      case 'expired':
        return PaymentRequestStatus.expired;
      case 'pending':
      default:
        return PaymentRequestStatus.pending;
    }
  }

  String toJson() => name;
}

/// Mirrors `chat_payment_requests`.
class PaymentRequest extends Equatable {
  const PaymentRequest({
    required this.id,
    required this.conversationId,
    required this.requesterProfileId,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.messageId,
    this.payerProfileId,
    this.note,
    this.paidAt,
  });

  final String id;
  final String conversationId;
  final String requesterProfileId;
  final int amountCents;
  final String currency;
  final PaymentRequestStatus status;
  final DateTime createdAt;
  final String? messageId;
  final String? payerProfileId;
  final String? note;
  final DateTime? paidAt;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: requireString(json, 'id', 'id'),
      conversationId:
          requireString(json, 'conversation_id', 'conversationId'),
      requesterProfileId:
          requireString(json, 'requester_profile_id', 'requesterProfileId'),
      amountCents: readInt(json, 'amount_cents', 'amountCents') ?? 0,
      currency: readJson<String>(json, 'currency', 'currency') ?? 'USD',
      status: PaymentRequestStatus.fromJson(
        readJson<String>(json, 'status', 'status'),
      ),
      createdAt: parseTimestamp(
        readJson<dynamic>(json, 'created_at', 'createdAt'),
      ),
      messageId: readJson<String>(json, 'message_id', 'messageId'),
      payerProfileId:
          readJson<String>(json, 'payer_profile_id', 'payerProfileId'),
      note: readJson<String>(json, 'note', 'note'),
      paidAt: readJson<dynamic>(json, 'paid_at', 'paidAt') != null
          ? parseTimestamp(readJson<dynamic>(json, 'paid_at', 'paidAt'))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'requester_profile_id': requesterProfileId,
        'amount_cents': amountCents,
        'currency': currency,
        'status': status.toJson(),
        'created_at': createdAt.toIso8601String(),
        'message_id': messageId,
        'payer_profile_id': payerProfileId,
        'note': note,
        'paid_at': paidAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        conversationId,
        requesterProfileId,
        amountCents,
        currency,
        status,
        createdAt,
        messageId,
        payerProfileId,
        note,
        paidAt,
      ];
}
