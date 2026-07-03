import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';
import 'message_attachment.dart';
import 'payment_request.dart';
import 'reaction.dart';

enum MessageStatus {
  sending,
  sent,
  failed,
}

/// Mirrors `chat_messages` (+ joined reactions).
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    required this.body,
    required this.createdAt,
    this.updatedAt,
    this.replyToMessageId,
    this.replyPreview,
    this.isSystem = false,
    this.reactions = const [],
    this.readByProfileIds = const [],
    this.status = MessageStatus.sent,
    this.clientTempId,
    this.attachments = const [],
    this.uploadProgress,
    this.paymentRequest,
  });

  final String id;
  final String conversationId;
  final String senderProfileId;
  final String body;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? replyToMessageId;
  final String? replyPreview;
  final bool isSystem;
  final List<Reaction> reactions;
  final List<String> readByProfileIds;
  final MessageStatus status;
  final String? clientTempId;
  final List<MessageAttachment> attachments;
  final double? uploadProgress;
  final PaymentRequest? paymentRequest;

  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasPaymentRequest => paymentRequest != null;

  bool get isOptimistic =>
      status == MessageStatus.sending || id.startsWith('temp-');

  bool get isFailed => status == MessageStatus.failed;

  factory Message.fromJson(Map<String, dynamic> json) {
    final reactionsJson = readJson<List<dynamic>>(
          json,
          'chat_message_reactions',
          'reactions',
        ) ??
        readJson<List<dynamic>>(json, 'reactions', 'reactions') ??
        [];

    final readBy = readJson<List<dynamic>>(
          json,
          'read_by_profile_ids',
          'readByProfileIds',
        ) ??
        [];

    final attachmentsJson = readJson<List<dynamic>>(
          json,
          'chat_message_attachments',
          'attachments',
        ) ??
        readJson<List<dynamic>>(json, 'attachments', 'attachments') ??
        [];

    final paymentRequestJson = readJson<dynamic>(
      json,
      'chat_payment_requests',
      'paymentRequest',
    );
    PaymentRequest? paymentRequest;
    if (paymentRequestJson is Map<String, dynamic>) {
      paymentRequest = PaymentRequest.fromJson(paymentRequestJson);
    } else if (paymentRequestJson is List && paymentRequestJson.isNotEmpty) {
      final first = paymentRequestJson.first;
      if (first is Map<String, dynamic>) {
        paymentRequest = PaymentRequest.fromJson(first);
      }
    }

    return Message(
      id: requireString(json, 'id', 'id'),
      conversationId:
          requireString(json, 'conversation_id', 'conversationId'),
      senderProfileId:
          requireString(json, 'sender_profile_id', 'senderProfileId'),
      body: readJson<String>(json, 'body_md', 'bodyMd') ??
          readJson<String>(json, 'body', 'body') ??
          '',
      createdAt: parseTimestamp(
        readJson<dynamic>(json, 'created_at', 'createdAt'),
      ),
      updatedAt: readJson<dynamic>(json, 'updated_at', 'updatedAt') != null
          ? parseTimestamp(
              readJson<dynamic>(json, 'updated_at', 'updatedAt'),
            )
          : null,
      replyToMessageId:
          readJson<String>(json, 'reply_to_message_id', 'replyToMessageId'),
      replyPreview: readJson<String>(json, 'reply_preview', 'replyPreview'),
      isSystem: readJson<bool>(json, 'is_system', 'isSystem') ?? false,
      reactions: reactionsJson
          .whereType<Map<String, dynamic>>()
          .map(Reaction.fromJson)
          .toList(),
      readByProfileIds: readBy.map((e) => e.toString()).toList(),
      attachments: attachmentsJson
          .whereType<Map<String, dynamic>>()
          .map(MessageAttachment.fromJson)
          .toList(),
      paymentRequest: paymentRequest,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_profile_id': senderProfileId,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'reply_to_message_id': replyToMessageId,
        'reply_preview': replyPreview,
        'is_system': isSystem,
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'read_by_profile_ids': readByProfileIds,
      };

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderProfileId,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? replyToMessageId,
    String? replyPreview,
    bool? isSystem,
    List<Reaction>? reactions,
    List<String>? readByProfileIds,
    MessageStatus? status,
    String? clientTempId,
    List<MessageAttachment>? attachments,
    double? uploadProgress,
    PaymentRequest? paymentRequest,
    bool clearUploadProgress = false,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderProfileId: senderProfileId ?? this.senderProfileId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyPreview: replyPreview ?? this.replyPreview,
      isSystem: isSystem ?? this.isSystem,
      reactions: reactions ?? this.reactions,
      readByProfileIds: readByProfileIds ?? this.readByProfileIds,
      status: status ?? this.status,
      clientTempId: clientTempId ?? this.clientTempId,
      attachments: attachments ?? this.attachments,
      uploadProgress:
          clearUploadProgress ? null : uploadProgress ?? this.uploadProgress,
      paymentRequest: paymentRequest ?? this.paymentRequest,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderProfileId,
        body,
        createdAt,
        updatedAt,
        replyToMessageId,
        replyPreview,
        isSystem,
        reactions,
        readByProfileIds,
        status,
        clientTempId,
        attachments,
        uploadProgress,
        paymentRequest,
      ];
}

/// Groups consecutive messages from the same sender on the same day.
class MessageGroup extends Equatable {
  const MessageGroup({
    required this.messages,
    required this.senderProfileId,
    required this.day,
    required this.showAvatar,
  });

  final List<Message> messages;
  final String senderProfileId;
  final DateTime day;
  final bool showAvatar;

  Message get first => messages.first;
  Message get last => messages.last;

  @override
  List<Object?> get props => [messages, senderProfileId, day, showAvatar];
}
