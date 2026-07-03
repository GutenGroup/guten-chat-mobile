import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubit/conversation_cubit.dart';
import '../theme/chat_theme.dart';
import 'chat_composer.dart';
import 'conversation_header.dart';
import 'groups/group_icon_picker.dart';
import 'groups/manage_community_sheet.dart';
import 'message_list_view.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.features,
    required this.repository,
    this.brandMarks = const [],
    this.title,
    this.onBack,
    this.onUploadGroupIcon,
  });

  final String conversationId;
  final ChatFeatures features;
  final ChatRepository repository;
  final List<BrandReactionMark> brandMarks;
  final String? title;
  final VoidCallback? onBack;
  final GroupIconUploadCallback? onUploadGroupIcon;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final resolvedTitle =
            title ?? state.conversation?.title ?? 'Conversation';
        final isGroup = state.isGroup;
        final isOnline = features.presence &&
            state.onlineProfileIds.isNotEmpty &&
            !isGroup;

        return Scaffold(
          // The composer is the single, explicit owner of the keyboard inset
          // (it pads itself by viewInsets — see ChatComposer.build). With the
          // default resize, the Scaffold would strip viewInsets from the body
          // and silently own the inset instead; that inert second layer goes
          // double the moment a host nests this under another resizing
          // ancestor. Explicit false = one owner, composer flush on the
          // keyboard, always (WhatsApp standard, Daniel 2026-07-03).
          resizeToAvoidBottomInset: false,
          appBar: ConversationHeader(
            title: resolvedTitle,
            conversation: state.conversation,
            onBack: onBack,
            isOnline: isOnline,
            onManage: isGroup
                ? () => _showGroupMenu(context, state)
                : () => _showChatMenu(context, state),
          ),
          body: Column(
            children: [
              Expanded(
                child: MessageListView(
                  features: features,
                  brandMarks: brandMarks,
                  repository: repository,
                ),
              ),
              ChatComposer(
                features: features,
                brandMarks: brandMarks,
                replyToMessage: state.replyToMessage,
                onClearReply: () =>
                    context.read<ConversationCubit>().setReplyTo(null),
                onSend: (text) =>
                    context.read<ConversationCubit>().sendMessage(text),
                onAttachment: (request) => context
                    .read<ConversationCubit>()
                    .sendAttachment(request),
                onTypingChanged: (isTyping) => context
                    .read<ConversationCubit>()
                    .notifyTyping(isTyping),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGroupMenu(
    BuildContext context,
    ConversationState state,
  ) async {
    final theme = chatThemeOf(context);
    final cubit = context.read<ConversationCubit>();
    final participant = state.participants
        .where((p) => p.profileId == state.currentProfileId)
        .firstOrNull;
    final isMuted = participant?.isMuted ?? false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: theme.inkColor,
              ),
              title: Text(
                isMuted ? 'Unmute chat' : 'Mute chat',
                style: TextStyle(color: theme.inkColor),
              ),
              onTap: () {
                Navigator.pop(context);
                cubit.toggleMute(!isMuted);
              },
            ),
            ListTile(
              leading: Icon(Icons.groups_outlined, color: theme.inkColor),
              title: Text(
                'Manage community',
                style: TextStyle(color: theme.inkColor),
              ),
              onTap: () {
                Navigator.pop(context);
                if (state.conversation != null) {
                  ManageCommunitySheet.show(
                    context,
                    conversation: state.conversation!,
                    participants: state.participants,
                    profiles: state.profiles,
                    currentProfileId: state.currentProfileId ?? '',
                    features: features,
                    repository: repository,
                    onUpdated: () => cubit.load(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChatMenu(
    BuildContext context,
    ConversationState state,
  ) async {
    final theme = chatThemeOf(context);
    final cubit = context.read<ConversationCubit>();
    final participant = state.participants
        .where((p) => p.profileId == state.currentProfileId)
        .firstOrNull;
    final isMuted = participant?.isMuted ?? false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: theme.inkColor,
              ),
              title: Text(
                isMuted ? 'Unmute chat' : 'Mute chat',
                style: TextStyle(color: theme.inkColor),
              ),
              onTap: () {
                Navigator.pop(context);
                cubit.toggleMute(!isMuted);
              },
            ),
          ],
        ),
      ),
    );
  }
}
