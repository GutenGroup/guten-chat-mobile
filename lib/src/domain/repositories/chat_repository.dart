import '../models/conversation.dart';
import '../models/message.dart';
import '../models/participant.dart';
import '../models/payment_request.dart';
import '../models/reaction.dart';
import '../models/tip.dart';

/// Realtime events emitted by [ConversationChannel].
sealed class ConversationEvent {
  const ConversationEvent();
}

class MessagesUpdated extends ConversationEvent {
  const MessagesUpdated(this.messages);
  final List<Message> messages;
}

class MessageInserted extends ConversationEvent {
  const MessageInserted(this.message);
  final Message message;
}

class MessageUpdated extends ConversationEvent {
  const MessageUpdated(this.message);
  final Message message;
}

class ReactionChanged extends ConversationEvent {
  const ReactionChanged({
    required this.messageId,
    required this.reactions,
  });

  final String messageId;
  final List<Reaction> reactions;
}

class TypingChanged extends ConversationEvent {
  const TypingChanged(this.typingProfileIds);
  final List<String> typingProfileIds;
}

class PresenceChanged extends ConversationEvent {
  const PresenceChanged(this.onlineProfileIds);
  final Set<String> onlineProfileIds;
}

class ReadReceiptsChanged extends ConversationEvent {
  const ReadReceiptsChanged(this.participants);
  final List<Participant> participants;
}

/// Contract for inbox + conversation operations against the shared `chat_*`
/// schema.
abstract class ChatRepository {
  Future<String> getCurrentProfileId();

  Future<List<Conversation>> fetchConversations();

  Future<Conversation> fetchConversation(String conversationId);

  Future<List<Participant>> fetchParticipants(String conversationId);

  Future<List<Message>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  });

  Future<String> createDm(String otherProfileId);

  Future<String> createGroup({
    required String title,
    required List<String> memberProfileIds,
    String? imageUrl,
    bool isPaid = false,
    int? joinPriceCents,
    String? joinCurrency,
  });

  Future<void> addGroupMember(String conversationId, String profileId);

  Future<void> removeGroupMember(String conversationId, String profileId);

  Future<void> leaveGroup(String conversationId);

  Future<void> setGroupRole(
    String conversationId,
    String profileId,
    ParticipantRole role,
  );

  Future<void> joinGroup(String conversationId);

  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? replyToMessageId,
    String? clientTempId,
  });

  Future<List<Reaction>> toggleReaction({
    required String messageId,
    required String value,
    required ReactionKind kind,
  });

  Future<void> markRead(String conversationId, {String? messageId});

  Future<PaymentRequest> createPaymentRequest({
    required String conversationId,
    required int amountCents,
    required String currency,
    String? note,
    String? messageId,
  });

  Future<Tip> sendTip({
    required String conversationId,
    required String recipientProfileId,
    required int amountCents,
    required String currency,
    String? note,
    String? messageId,
  });

  Stream<ConversationEvent> watchConversation(String conversationId);

  Future<void> setTyping(String conversationId, bool isTyping);

  void dispose();
}
