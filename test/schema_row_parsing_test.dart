import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';

/// Fixtures shaped EXACTLY like the live `chat_*` schema rows (column names
/// from packages/schema in guten-chat — verified against the Fysigo prod DB
/// 2026-07-06). The 0.6.0 reconciliation missed reactions, payment requests,
/// and tips; these tests pin every model to the real column names so a
/// schema-shaped row can never crash a conversation again.
void main() {
  group('Reaction — live schema rows', () {
    final schemaRow = <String, dynamic>{
      'id': 'r-1',
      'message_id': 'm-1',
      'conversation_id': 'c-1',
      'profile_id': 'p-1',
      'kind': 'emoji',
      'reaction': '👍',
      'created_at': '2026-07-06T12:00:00Z',
    };

    test('parses the `reaction` column (schema truth)', () {
      final reaction = Reaction.fromJson(schemaRow);
      expect(reaction.value, '👍');
      expect(reaction.kind, ReactionKind.emoji);
      expect(reaction.messageId, 'm-1');
    });

    test('legacy `value` payloads still parse', () {
      final legacy = Map<String, dynamic>.from(schemaRow)
        ..remove('reaction')
        ..['value'] = '🔥';
      expect(Reaction.fromJson(legacy).value, '🔥');
    });

    test('toJson round-trips through fromJson', () {
      final reaction = Reaction.fromJson(schemaRow);
      expect(Reaction.fromJson(reaction.toJson()).value, '👍');
    });
  });

  group('PaymentRequest — live schema rows', () {
    final schemaRow = <String, dynamic>{
      'id': 'pr-1',
      'conversation_id': 'c-1',
      'message_id': 'm-1',
      'requested_by_profile_id': 'p-req',
      'requested_from_profile_id': null,
      'amount_cents': 2500,
      'currency': 'usd',
      'status': 'open',
      'paid_by_profile_id': null,
      'paid_at': null,
      'created_at': '2026-07-06T12:00:00Z',
    };

    test('parses `requested_by_profile_id` (schema truth)', () {
      final pr = PaymentRequest.fromJson(schemaRow);
      expect(pr.requesterProfileId, 'p-req');
      expect(pr.amountCents, 2500);
    });

    test('schema `open` status maps to pending; `canceled` (one l) parses',
        () {
      expect(
        PaymentRequest.fromJson(schemaRow).status,
        PaymentRequestStatus.pending,
      );
      final canceled = Map<String, dynamic>.from(schemaRow)
        ..['status'] = 'canceled';
      expect(
        PaymentRequest.fromJson(canceled).status,
        PaymentRequestStatus.cancelled,
      );
    });

    test('paid row carries `paid_by_profile_id` into payerProfileId', () {
      final paid = Map<String, dynamic>.from(schemaRow)
        ..['status'] = 'paid'
        ..['paid_by_profile_id'] = 'p-payer'
        ..['paid_at'] = '2026-07-06T13:00:00Z';
      final pr = PaymentRequest.fromJson(paid);
      expect(pr.payerProfileId, 'p-payer');
      expect(pr.status, PaymentRequestStatus.paid);
    });

    test('legacy `requester_profile_id` payloads still parse', () {
      final legacy = Map<String, dynamic>.from(schemaRow)
        ..remove('requested_by_profile_id')
        ..['requester_profile_id'] = 'p-legacy';
      expect(
        PaymentRequest.fromJson(legacy).requesterProfileId,
        'p-legacy',
      );
    });
  });

  group('Tip — live schema rows', () {
    final schemaRow = <String, dynamic>{
      'id': 't-1',
      'conversation_id': 'c-1',
      'message_id': 'm-1',
      'from_profile_id': 'p-from',
      'to_profile_id': 'p-to',
      'amount_cents': 500,
      'currency': 'usd',
      'status': 'sent',
      'created_at': '2026-07-06T12:00:00Z',
    };

    test('parses `from_profile_id` / `to_profile_id` (schema truth)', () {
      final tip = Tip.fromJson(schemaRow);
      expect(tip.senderProfileId, 'p-from');
      expect(tip.recipientProfileId, 'p-to');
    });

    test('legacy sender/recipient payloads still parse', () {
      final legacy = Map<String, dynamic>.from(schemaRow)
        ..remove('from_profile_id')
        ..remove('to_profile_id')
        ..['sender_profile_id'] = 'p-s'
        ..['recipient_profile_id'] = 'p-r';
      final tip = Tip.fromJson(legacy);
      expect(tip.senderProfileId, 'p-s');
      expect(tip.recipientProfileId, 'p-r');
    });
  });

  group('Message — embedded schema rows + lenient decorations', () {
    Map<String, dynamic> messageRow({
      List<dynamic>? reactions,
      dynamic paymentRequests,
    }) {
      return <String, dynamic>{
        'id': 'm-1',
        'conversation_id': 'c-1',
        'sender_profile_id': 'p-1',
        'body_md': 'hello',
        'created_at': '2026-07-06T12:00:00Z',
        if (reactions != null) 'chat_message_reactions': reactions,
        if (paymentRequests != null) 'chat_payment_requests': paymentRequests,
      };
    }

    test('message with schema-shaped reactions parses (the b30 crash)', () {
      final message = Message.fromJson(
        messageRow(
          reactions: [
            {
              'message_id': 'm-1',
              'profile_id': 'p-1',
              'kind': 'emoji',
              'reaction': '❤️',
              'created_at': '2026-07-06T12:00:00Z',
            },
          ],
        ),
      );
      expect(message.reactions, hasLength(1));
      expect(message.reactions.single.value, '❤️');
    });

    test('one malformed reaction row is dropped, not fatal', () {
      final message = Message.fromJson(
        messageRow(
          reactions: [
            {'garbage': true},
            {
              'message_id': 'm-1',
              'profile_id': 'p-1',
              'reaction': '👍',
              'created_at': '2026-07-06T12:00:00Z',
            },
          ],
        ),
      );
      expect(message.reactions, hasLength(1));
      expect(message.reactions.single.value, '👍');
    });

    test('a malformed embedded payment request degrades to null, not fatal',
        () {
      final message = Message.fromJson(
        messageRow(paymentRequests: [
          {'garbage': true},
        ]),
      );
      expect(message.paymentRequest, isNull);
      expect(message.body, 'hello');
    });

    test('schema-shaped embedded payment request parses', () {
      final message = Message.fromJson(
        messageRow(paymentRequests: [
          {
            'id': 'pr-1',
            'conversation_id': 'c-1',
            'requested_by_profile_id': 'p-req',
            'amount_cents': 1000,
            'status': 'open',
            'created_at': '2026-07-06T12:00:00Z',
          },
        ]),
      );
      expect(message.paymentRequest, isNotNull);
      expect(message.paymentRequest!.requesterProfileId, 'p-req');
    });
  });
}
