import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_attachment.dart';
import '../../domain/models/participant.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/reaction.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/attachment_send_request.dart';
import '../utils/message_list_builder.dart';

class ConversationState extends Equatable {
  const ConversationState({
    this.conversation,
    this.messages = const [],
    this.participants = const [],
    this.isLoading = false,
    this.error,
    this.currentProfileId,
    this.typingProfileIds = const [],
    this.onlineProfileIds = const {},
    this.replyToMessage,
    this.newMessageCount = 0,
    this.isAtBottom = true,
    this.profiles = const {},
  });

  final Conversation? conversation;
  final List<Message> messages;
  final List<Participant> participants;
  final bool isLoading;
  final String? error;
  final String? currentProfileId;
  final List<String> typingProfileIds;
  final Set<String> onlineProfileIds;
  final Message? replyToMessage;
  final int newMessageCount;
  final bool isAtBottom;
  final Map<String, ChatProfile> profiles;

  List<MessageListItem> get listItems => buildMessageListItems(
        messages,
        isGroup: conversation?.isGroup ?? false,
      );

  bool get isGroup => conversation?.isGroup ?? false;

  ConversationState copyWith({
    Conversation? conversation,
    List<Message>? messages,
    List<Participant>? participants,
    bool? isLoading,
    String? error,
    String? currentProfileId,
    List<String>? typingProfileIds,
    Set<String>? onlineProfileIds,
    Message? replyToMessage,
    bool clearReply = false,
    int? newMessageCount,
    bool? isAtBottom,
    Map<String, ChatProfile>? profiles,
  }) {
    return ConversationState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      participants: participants ?? this.participants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentProfileId: currentProfileId ?? this.currentProfileId,
      typingProfileIds: typingProfileIds ?? this.typingProfileIds,
      onlineProfileIds: onlineProfileIds ?? this.onlineProfileIds,
      replyToMessage: clearReply ? null : replyToMessage ?? this.replyToMessage,
      newMessageCount: newMessageCount ?? this.newMessageCount,
      isAtBottom: isAtBottom ?? this.isAtBottom,
      profiles: profiles ?? this.profiles,
    );
  }

  @override
  List<Object?> get props => [
        conversation,
        messages,
        participants,
        isLoading,
        error,
        currentProfileId,
        typingProfileIds,
        onlineProfileIds,
        replyToMessage,
        newMessageCount,
        isAtBottom,
        profiles,
      ];
}

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required String conversationId,
    required ChatRepository repository,
    required ProfileLookup profileLookup,
    required ChatFeatures features,
  })  : _conversationId = conversationId,
        _repository = repository,
        _profileLookup = profileLookup,
        _features = features,
        super(const ConversationState(isLoading: true));

  final String _conversationId;
  final ChatRepository _repository;
  final ProfileLookup _profileLookup;
  final ChatFeatures _features;
  final _uuid = const Uuid();

  StreamSubscription<ConversationEvent>? _subscription;
  Timer? _typingDebounce;
  final _optimisticMessages = <Message>[];
  final _pendingReactions = <String, List<Reaction>>{};

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final profileId = await _repository.getCurrentProfileId();
      final conversation = await _repository.fetchConversation(_conversationId);
      final participants =
          await _repository.fetchParticipants(_conversationId);
      final messages = await _repository.fetchMessages(_conversationId);

      final profiles = Map<String, ChatProfile>.from(state.profiles);
      for (final participant in participants) {
        profiles[participant.profileId] =
            await _safeLookup(participant.profileId);
      }

      emit(
        state.copyWith(
          conversation: conversation,
          participants: participants,
          messages: messages,
          currentProfileId: profileId,
          isLoading: false,
          profiles: profiles,
          isAtBottom: true,
          newMessageCount: 0,
        ),
      );

      await _repository.markRead(_conversationId);
      await _listen();
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _listen() async {
    await _subscription?.cancel();
    _subscription = _repository.watchConversation(_conversationId).listen(
      (event) {
        switch (event) {
          case MessageInserted(:final message):
            _onMessageInserted(message);
          case MessageUpdated(:final message):
            _onMessageUpdated(message);
          case ReactionChanged(:final messageId, :final reactions):
            _onReactionsChanged(messageId, reactions);
          case TypingChanged(:final typingProfileIds):
            emit(state.copyWith(typingProfileIds: typingProfileIds));
          case PresenceChanged(:final onlineProfileIds):
            emit(state.copyWith(onlineProfileIds: onlineProfileIds));
          case ReadReceiptsChanged(:final participants):
            emit(state.copyWith(participants: participants));
          case MessagesUpdated(:final messages):
            emit(state.copyWith(messages: messages));
        }
      },
      onError: (Object error) {
        emit(state.copyWith(error: error.toString()));
      },
    );
  }

  void _onMessageInserted(Message message) {
    if (message.clientTempId != null) {
      _optimisticMessages.removeWhere(
        (m) => m.clientTempId == message.clientTempId || m.id == message.clientTempId,
      );
    }

    final exists = state.messages.any((m) => m.id == message.id);
    if (exists) {
      return;
    }

    final isOwn = message.senderProfileId == state.currentProfileId;
    final messages = [...state.messages, message];

    if (isOwn || state.isAtBottom) {
      emit(
        state.copyWith(
          messages: messages,
          isAtBottom: true,
          newMessageCount: 0,
        ),
      );
      unawaited(_repository.markRead(_conversationId, messageId: message.id));
    } else {
      emit(
        state.copyWith(
          messages: messages,
          newMessageCount: state.newMessageCount + 1,
        ),
      );
    }
  }

  void _onMessageUpdated(Message message) {
    final messages = state.messages
        .map((m) => m.id == message.id ? message : m)
        .toList();
    emit(state.copyWith(messages: messages));
  }

  void _onReactionsChanged(String messageId, List<Reaction> reactions) {
    _pendingReactions.remove(messageId);
    final messages = state.messages
        .map(
          (m) => m.id == messageId ? m.copyWith(reactions: reactions) : m,
        )
        .toList();
    emit(state.copyWith(messages: messages));
  }

  Future<void> sendMessage(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || state.currentProfileId == null) {
      return;
    }

    final tempId = 'temp-${_uuid.v4()}';
    final reply = state.replyToMessage;
    final optimistic = createOptimisticMessage(
      tempId: tempId,
      conversationId: _conversationId,
      senderProfileId: state.currentProfileId!,
      body: trimmed,
      replyToMessageId: reply?.id,
      replyPreview: reply?.body,
    );

    _optimisticMessages.add(optimistic);
    final messages = mergeMessages(
      serverMessages: state.messages,
      optimisticMessages: _optimisticMessages,
    );

    emit(
      state.copyWith(
        messages: messages,
        clearReply: true,
        isAtBottom: true,
        newMessageCount: 0,
      ),
    );

    try {
      final sent = await _repository.sendMessage(
        conversationId: _conversationId,
        body: trimmed,
        replyToMessageId: reply?.id,
        clientTempId: tempId,
      );
      _optimisticMessages.removeWhere((m) => m.clientTempId == tempId);
      final reconciled = state.messages
          .where((m) => m.clientTempId != tempId)
          .toList()
        ..add(sent.copyWith(status: MessageStatus.sent));
      reconciled.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(state.copyWith(messages: reconciled));
      await _repository.markRead(_conversationId, messageId: sent.id);
    } catch (error) {
      _optimisticMessages.removeWhere((m) => m.clientTempId == tempId);
      final failed = optimistic.copyWith(status: MessageStatus.failed);
      final messagesWithFailed = mergeMessages(
        serverMessages:
            state.messages.where((m) => m.clientTempId != tempId).toList(),
        optimisticMessages: [failed],
      );
      emit(
        state.copyWith(
          messages: messagesWithFailed,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> sendAttachment(AttachmentSendRequest request) async {
    if (state.currentProfileId == null) {
      return;
    }

    final tempId = 'temp-${_uuid.v4()}';
    final optimisticAttachment = MessageAttachment(
      id: 'temp-att-$tempId',
      messageId: tempId,
      kind: request.kind,
      storagePath: request.localPath,
      widthPx: request.widthPx,
      heightPx: request.heightPx,
      fileSizeBytes: request.fileSizeBytes,
      originalFileName: request.fileName,
      durationMs: request.durationMs,
    );
    final optimistic = createOptimisticMessage(
      tempId: tempId,
      conversationId: _conversationId,
      senderProfileId: state.currentProfileId!,
      body: request.caption?.trim() ?? '',
      attachments: [optimisticAttachment],
      uploadProgress: 0,
    );

    _optimisticMessages.add(optimistic);
    final messages = mergeMessages(
      serverMessages: state.messages,
      optimisticMessages: _optimisticMessages,
    );

    emit(
      state.copyWith(
        messages: messages,
        isAtBottom: true,
        newMessageCount: 0,
      ),
    );

    try {
      final sent = await _repository.sendAttachment(
        conversationId: _conversationId,
        localPath: request.localPath,
        kind: request.kind,
        caption: request.caption,
        fileName: request.fileName,
        widthPx: request.widthPx,
        heightPx: request.heightPx,
        fileSizeBytes: request.fileSizeBytes,
        durationMs: request.durationMs,
        clientTempId: tempId,
        onProgress: (progress) {
          final updated = optimistic.copyWith(uploadProgress: progress);
          _optimisticMessages.removeWhere((m) => m.clientTempId == tempId);
          _optimisticMessages.add(updated);
          emit(
            state.copyWith(
              messages: mergeMessages(
                serverMessages: state.messages
                    .where((m) => m.clientTempId != tempId)
                    .toList(),
                optimisticMessages: _optimisticMessages,
              ),
            ),
          );
        },
      );
      _optimisticMessages.removeWhere((m) => m.clientTempId == tempId);
      final reconciled = state.messages
          .where((m) => m.clientTempId != tempId)
          .toList()
        ..add(sent.copyWith(status: MessageStatus.sent, clearUploadProgress: true));
      reconciled.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(state.copyWith(messages: reconciled));
      await _repository.markRead(_conversationId, messageId: sent.id);
    } catch (error) {
      _optimisticMessages.removeWhere((m) => m.clientTempId == tempId);
      final failed = optimistic.copyWith(
        status: MessageStatus.failed,
        clearUploadProgress: true,
      );
      final messagesWithFailed = mergeMessages(
        serverMessages:
            state.messages.where((m) => m.clientTempId != tempId).toList(),
        optimisticMessages: [failed],
      );
      emit(
        state.copyWith(
          messages: messagesWithFailed,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> sendTip({
    required String recipientProfileId,
    required int amountCents,
    required String currency,
    String? messageId,
    String? note,
  }) async {
    if (!_features.tipping || state.currentProfileId == null) {
      return;
    }

    try {
      await _repository.sendTip(
        conversationId: _conversationId,
        recipientProfileId: recipientProfileId,
        amountCents: amountCents,
        currency: currency,
        messageId: messageId,
        note: note,
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> toggleReaction({
    required String messageId,
    required String value,
    required ReactionKind kind,
  }) async {
    if (!_features.reactions) {
      return;
    }
    if (kind == ReactionKind.brand && !_features.brandReactions) {
      return;
    }

    final profileId = state.currentProfileId;
    if (profileId == null) {
      return;
    }

    final message = state.messages.firstWhere((m) => m.id == messageId);
    final existing = message.reactions.where(
      (r) =>
          r.profileId == profileId &&
          r.value == value &&
          r.kind == kind,
    );
    final snapshot = List<Reaction>.from(message.reactions);

    List<Reaction> optimistic;
    if (existing.isNotEmpty) {
      optimistic = message.reactions
          .where(
            (r) =>
                !(r.profileId == profileId &&
                    r.value == value &&
                    r.kind == kind),
          )
          .toList();
    } else {
      optimistic = [
        ...message.reactions,
        Reaction(
          messageId: messageId,
          profileId: profileId,
          value: value,
          kind: kind,
          createdAt: DateTime.now().toUtc(),
          isOptimistic: true,
        ),
      ];
    }

    _pendingReactions[messageId] = snapshot;
    final messages = state.messages
        .map(
          (m) => m.id == messageId ? m.copyWith(reactions: optimistic) : m,
        )
        .toList();
    emit(state.copyWith(messages: messages));

    try {
      final reactions = await _repository.toggleReaction(
        messageId: messageId,
        value: value,
        kind: kind,
      );
      _pendingReactions.remove(messageId);
      _onReactionsChanged(messageId, reactions);
    } catch (error) {
      final rollback = _pendingReactions.remove(messageId) ?? snapshot;
      final messagesRollback = state.messages
          .map(
            (m) => m.id == messageId ? m.copyWith(reactions: rollback) : m,
          )
          .toList();
      emit(
        state.copyWith(
          messages: messagesRollback,
          error: error.toString(),
        ),
      );
    }
  }

  void setReplyTo(Message? message) {
    if (!_features.replies) {
      return;
    }
    emit(state.copyWith(replyToMessage: message, clearReply: message == null));
  }

  Future<void> forwardMessage(Message message) async {
    final body = message.body.trim();
    final forwarded = body.isNotEmpty
        ? '↪ Forwarded:\n$body'
        : '↪ Forwarded attachment';
    await sendMessage(forwarded);
  }

  Future<void> deleteMessage(String messageId) async {
    final snapshot = state.messages;
    final messages =
        state.messages.where((m) => m.id != messageId).toList();
    emit(state.copyWith(messages: messages));

    try {
      await _repository.deleteMessage(messageId);
    } catch (error) {
      emit(
        state.copyWith(
          messages: snapshot,
          error: error.toString(),
        ),
      );
    }
  }

  void onScrollPosition({required bool isAtBottom}) {
    if (isAtBottom && state.newMessageCount > 0) {
      emit(state.copyWith(isAtBottom: true, newMessageCount: 0));
      final last = state.messages.lastOrNull;
      if (last != null) {
        unawaited(_repository.markRead(_conversationId, messageId: last.id));
      }
    } else if (!isAtBottom && isAtBottom != state.isAtBottom) {
      emit(state.copyWith(isAtBottom: false));
    } else if (isAtBottom != state.isAtBottom) {
      emit(state.copyWith(isAtBottom: isAtBottom));
    }
  }

  void jumpToLatest() {
    emit(state.copyWith(isAtBottom: true, newMessageCount: 0));
    final last = state.messages.lastOrNull;
    if (last != null) {
      unawaited(_repository.markRead(_conversationId, messageId: last.id));
    }
  }

  void notifyTyping(bool isTyping) {
    if (!_features.typingIndicators) {
      return;
    }
    _typingDebounce?.cancel();
    unawaited(_repository.setTyping(_conversationId, isTyping));
    if (isTyping) {
      _typingDebounce = Timer(const Duration(seconds: 3), () {
        unawaited(_repository.setTyping(_conversationId, false));
      });
    }
  }

  /// Per-chat mute — local optimistic update until host wires persistence.
  void toggleMute(bool muted) {
    final profileId = state.currentProfileId;
    if (profileId == null) {
      return;
    }
    final participants = state.participants
        .map(
          (p) => p.profileId == profileId ? p.copyWith(isMuted: muted) : p,
        )
        .toList();
    emit(state.copyWith(participants: participants));
  }

  Future<ChatProfile> _safeLookup(String profileId) async {
    try {
      return await _profileLookup(profileId);
    } catch (_) {
      return unknownProfile;
    }
  }

  @override
  Future<void> close() async {
    _typingDebounce?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}
