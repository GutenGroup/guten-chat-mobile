import 'dart:async';

import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_attachment.dart';
import '../../domain/models/participant.dart';
import '../../domain/models/payment_request.dart';
import '../../domain/models/reaction.dart';
import '../../domain/models/tip.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;
  final _channels = <String, ConversationChannel>{};
  String? _cachedProfileId;

  @override
  Future<String> getCurrentProfileId() async {
    _cachedProfileId ??= await _remote.getCurrentProfileId();
    return _cachedProfileId!;
  }

  @override
  Future<List<Conversation>> fetchConversations() =>
      _remote.fetchConversations();

  @override
  Future<Conversation> fetchConversation(String conversationId) =>
      _remote.fetchConversation(conversationId);

  @override
  Future<List<Participant>> fetchParticipants(String conversationId) =>
      _remote.fetchParticipants(conversationId);

  @override
  Future<List<Message>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) =>
      _remote.fetchMessages(conversationId, limit: limit, before: before);

  @override
  Future<String> createDm(String otherProfileId) =>
      _remote.createDm(otherProfileId);

  @override
  Future<String> createGroup({
    required String title,
    required List<String> memberProfileIds,
    String? imageUrl,
    bool isPaid = false,
    int? joinPriceCents,
    String? joinCurrency,
  }) =>
      _remote.createGroup(
        title: title,
        memberProfileIds: memberProfileIds,
        imageUrl: imageUrl,
        isPaid: isPaid,
        joinPriceCents: joinPriceCents,
        joinCurrency: joinCurrency,
      );

  @override
  Future<void> addGroupMember(String conversationId, String profileId) =>
      _remote.addGroupMember(conversationId, profileId);

  @override
  Future<void> removeGroupMember(String conversationId, String profileId) =>
      _remote.removeGroupMember(conversationId, profileId);

  @override
  Future<void> leaveGroup(String conversationId) =>
      _remote.leaveGroup(conversationId);

  @override
  Future<void> setGroupRole(
    String conversationId,
    String profileId,
    ParticipantRole role,
  ) =>
      _remote.setGroupRole(conversationId, profileId, role);

  @override
  Future<void> joinGroup(String conversationId) =>
      _remote.joinGroup(conversationId);

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? replyToMessageId,
    String? clientTempId,
  }) =>
      _remote.sendMessage(
        conversationId: conversationId,
        body: body,
        replyToMessageId: replyToMessageId,
        clientTempId: clientTempId,
      );

  @override
  Future<Message> sendAttachment({
    required String conversationId,
    required String localPath,
    required AttachmentKind kind,
    String? caption,
    String? fileName,
    int? widthPx,
    int? heightPx,
    int? fileSizeBytes,
    int? durationMs,
    String? clientTempId,
    void Function(double progress)? onProgress,
  }) =>
      _remote.sendAttachment(
        conversationId: conversationId,
        localPath: localPath,
        kind: kind,
        caption: caption,
        fileName: fileName,
        widthPx: widthPx,
        heightPx: heightPx,
        fileSizeBytes: fileSizeBytes,
        durationMs: durationMs,
        clientTempId: clientTempId,
        onProgress: onProgress,
      );

  @override
  Future<void> deleteMessage(String messageId) =>
      _remote.deleteMessage(messageId);

  @override
  Future<String> createSignedAttachmentUrl(String storagePath) =>
      _remote.createSignedAttachmentUrl(storagePath);

  @override
  Future<List<int>> downloadAttachmentBytes(String storagePath) =>
      _remote.downloadAttachmentBytes(storagePath);

  @override
  Future<List<Reaction>> toggleReaction({
    required String messageId,
    required String value,
    required ReactionKind kind,
  }) =>
      _remote.toggleReaction(messageId: messageId, value: value, kind: kind);

  @override
  Future<void> markRead(String conversationId, {String? messageId}) =>
      _remote.markRead(conversationId, messageId: messageId);

  @override
  Future<PaymentRequest> createPaymentRequest({
    required String conversationId,
    required int amountCents,
    required String currency,
    String? note,
    String? messageId,
  }) =>
      _remote.createPaymentRequest(
        conversationId: conversationId,
        amountCents: amountCents,
        currency: currency,
        note: note,
        messageId: messageId,
      );

  @override
  Future<Tip> sendTip({
    required String conversationId,
    required String recipientProfileId,
    required int amountCents,
    required String currency,
    String? note,
    String? messageId,
  }) =>
      _remote.sendTip(
        conversationId: conversationId,
        recipientProfileId: recipientProfileId,
        amountCents: amountCents,
        currency: currency,
        note: note,
        messageId: messageId,
      );

  @override
  Stream<ConversationEvent> watchConversation(String conversationId) async* {
    final profileId = await getCurrentProfileId();
    final channel = ConversationChannel(
      client: _remote.client,
      conversationId: conversationId,
      currentProfileId: profileId,
    );
    _channels[conversationId] = channel;
    await channel.subscribe();
    yield* channel.stream;
  }

  @override
  Future<void> setTyping(String conversationId, bool isTyping) async {
    final channel = _channels[conversationId];
    await channel?.broadcastTyping(isTyping);
  }

  @override
  void dispose() {
    for (final channel in _channels.values) {
      unawaited(channel.dispose());
    }
    _channels.clear();
  }
}
