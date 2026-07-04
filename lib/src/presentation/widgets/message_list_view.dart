import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/models/message.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/reaction.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubit/conversation_cubit.dart';
import '../theme/chat_theme.dart';
import '../utils/message_list_builder.dart';
import 'day_divider.dart';
import 'jump_to_latest_pill.dart';
import 'message_bubble.dart';
import 'message_context_menu.dart';
import 'typing_indicator.dart';

class MessageListView extends StatefulWidget {
  const MessageListView({
    super.key,
    required this.features,
    required this.repository,
    this.brandMarks = const [],
  });

  final ChatFeatures features;
  final ChatRepository repository;
  final List<BrandReactionMark> brandMarks;

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final _scrollController = ScrollController();
  final _bubbleKeys = <String, GlobalKey>{};
  bool _pendingScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    MessageContextMenu.dismiss();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  GlobalKey _keyForMessage(String messageId) {
    return _bubbleKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  void _onScroll() {
    if (MessageContextMenu.isVisible) {
      MessageContextMenu.dismiss();
    }

    if (!_scrollController.hasClients) {
      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final isAtBottom = (max - current) < 48;
    context.read<ConversationCubit>().onScrollPosition(isAtBottom: isAtBottom);
  }

  void _scrollToBottom({bool instant = false}) {
    if (!_scrollController.hasClients) {
      _pendingScrollToBottom = true;
      return;
    }
    final target = _scrollController.position.maxScrollExtent;
    if (instant) {
      _scrollController.jumpTo(target);
    } else {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  int _seenCount(
    Message message,
    ConversationState state,
  ) {
    if (!widget.features.readReceipts) {
      return 0;
    }
    return state.participants
        .where(
          (p) =>
              p.profileId != message.senderProfileId &&
              p.lastReadMessageId != null,
        )
        .length;
  }

  void _openContextMenu({
    required BuildContext context,
    required Message message,
    required bool isOwn,
    required bool isGroupedWithPrevious,
    required ConversationState state,
  }) {
    final bubbleKey = _keyForMessage(message.id);
    final renderBox =
        bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final anchorRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final theme = chatThemeOf(context);
    final isEmphasized = message.reactions.any(
      (r) => r.kind == ReactionKind.brand,
    );
    final bubbleColor = isEmphasized
        ? theme.accentColor
        : (isOwn ? theme.sentBubbleColor : theme.receivedBubbleColor);
    final textColor = isEmphasized
        ? (theme.isDark ? Colors.black : Colors.white)
        : (isOwn ? theme.sentTextColor : theme.receivedTextColor);

    final cubit = context.read<ConversationCubit>();

    MessageContextMenu.show(
      context: context,
      anchorRect: anchorRect,
      message: message,
      isOwn: isOwn,
      features: widget.features,
      brandMarks: widget.brandMarks,
      onDismiss: () {},
      onReply: () => cubit.setReplyTo(message),
      onToggleReaction: (value, kind) => cubit.toggleReaction(
        messageId: message.id,
        value: value,
        kind: kind,
      ),
      onForward: () => cubit.forwardMessage(message),
      onDelete: isOwn && !message.isOptimistic
          ? () => cubit.deleteMessage(message.id)
          : null,
      onSendTip: widget.features.tipping && !isOwn
          ? (amount, _) => cubit.sendTip(
                recipientProfileId: message.senderProfileId,
                amountCents: amount,
                messageId: message.id,
              )
          : null,
      messagePreview: Material(
        color: Colors.transparent,
        child: MessageBubbleContent(
          message: message,
          isOwn: isOwn,
          isGroupedWithPrevious: isGroupedWithPrevious,
          features: widget.features,
          bubbleColor: bubbleColor,
          textColor: textColor,
          resolveUrl: widget.repository.createSignedAttachmentUrl,
          resolveBytes: widget.repository.downloadAttachmentBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return BlocConsumer<ConversationCubit, ConversationState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          previous.isAtBottom != current.isAtBottom ||
          previous.newMessageCount != current.newMessageCount,
      listener: (context, state) {
        final last = state.messages.lastOrNull;
        final isOwnLast =
            last?.senderProfileId == state.currentProfileId;

        if (state.isAtBottom || isOwnLast) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(instant: isOwnLast);
          });
        }

        if (_pendingScrollToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(instant: true);
            _pendingScrollToBottom = false;
          });
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.messages.isEmpty) {
          return Center(child: Text(state.error!));
        }

        final items = state.listItems;

        return Stack(
          children: [
            ColoredBox(
              color: theme.backgroundColor,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is DayDividerItem) {
                    return DayDivider(day: item.day);
                  }
                  if (item is MessageItem) {
                    final message = item.message;
                    final isOwn =
                        message.senderProfileId == state.currentProfileId;
                    final profile = state.profiles[message.senderProfileId] ??
                        unknownProfile;
                    return MessageBubble(
                      message: message,
                      isOwn: isOwn,
                      showAvatar: item.showAvatar,
                      isGroupedWithPrevious: item.isGroupedWithPrevious,
                      profile: profile,
                      features: widget.features,
                      isGroup: state.isGroup,
                      seenCount: _seenCount(message, state),
                      brandMarks: widget.brandMarks,
                      repository: widget.repository,
                      bubbleKey: _keyForMessage(message.id),
                      onReply: () => context
                          .read<ConversationCubit>()
                          .setReplyTo(message),
                      onToggleReaction: (value, kind) => context
                          .read<ConversationCubit>()
                          .toggleReaction(
                            messageId: message.id,
                            value: value,
                            kind: kind,
                          ),
                      onOpenContextMenu: message.isSystem
                          ? null
                          : () => _openContextMenu(
                                context: context,
                                message: message,
                                isOwn: isOwn,
                                isGroupedWithPrevious:
                                    item.isGroupedWithPrevious,
                                state: state,
                              ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            JumpToLatestPill(
              count: state.newMessageCount,
              onTap: () {
                context.read<ConversationCubit>().jumpToLatest();
                _scrollToBottom();
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TypingIndicator(
                typingProfileIds: state.typingProfileIds,
                profiles: state.profiles,
              ),
            ),
          ],
        );
      },
    );
  }
}
