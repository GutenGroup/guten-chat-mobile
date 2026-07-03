import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../cubit/inbox_cubit.dart';
import '../../theme/chat_theme.dart';
import '../groups/group_icon_mark.dart';
import '../groups/group_icon_picker.dart';

/// Chats tab — DMs and non-community group threads (one scroll).
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({
    super.key,
    required this.onConversationTap,
    required this.repository,
    this.onCreateGroup,
    this.onUploadGroupIcon,
    this.buildLabel,
  });

  final ValueChanged<Conversation> onConversationTap;
  final ChatRepository repository;
  final VoidCallback? onCreateGroup;
  final GroupIconUploadCallback? onUploadGroupIcon;

  /// Optional build stamp rendered as a tiny caption under the list — lets
  /// testers tell exactly which build feedback refers to (mirrors the web
  /// app's version footer).
  final String? buildLabel;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        final chats = state.filteredConversations
            .where((c) => c.isDm || !c.isPaid)
            .toList();

        return ColoredBox(
          color: theme.backgroundColor,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.backgroundColor,
                title: Text(
                  'Chats',
                  style: TextStyle(
                    color: theme.inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  if (onCreateGroup != null)
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: theme.inkColor),
                      onPressed: onCreateGroup,
                      tooltip: 'New chat',
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search, color: theme.subtleTextColor),
                      filled: true,
                      fillColor: theme.searchFieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    style: TextStyle(color: theme.inkColor),
                    onChanged: (query) =>
                        context.read<InboxCubit>().setSearchQuery(query),
                  ),
                ),
              ),
              if (state.isLoading && chats.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null && chats.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.read<InboxCubit>().load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (chats.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No chats yet',
                      style: TextStyle(color: theme.subtleTextColor),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final conversation = chats[index];
                      final profile = conversation.createdByProfileId != null
                          ? state.profileNames[
                              conversation.createdByProfileId!]
                          : null;
                      return _ChatTile(
                        conversation: conversation,
                        profile: profile,
                        onTap: () => onConversationTap(conversation),
                      );
                    },
                    childCount: chats.length,
                  ),
                ),
              if (buildLabel != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        buildLabel!,
                        style: TextStyle(
                          color: theme.subtleTextColor.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.conversation,
    required this.profile,
    required this.onTap,
  });

  final Conversation conversation;
  final ChatProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final title = conversation.title ??
        (profile?.name ?? (conversation.isDm ? 'Direct message' : 'Group'));
    final subtitle = conversation.lastMessagePreview ?? '';
    final time = formatConversationTime(conversation.lastMessageAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GroupAvatar(
              title: title,
              imageUrl: conversation.imageUrl,
              markId: conversation.isGroup
                  ? GroupIconMarkId.monogram
                  : null,
              radius: 26,
              backgroundColor: theme.surfaceColor,
              foregroundColor: theme.inkColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.inkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.subtleTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      color: theme.subtleTextColor,
                      fontSize: 12,
                    ),
                  ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.inkColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: TextStyle(
                        color: theme.backgroundColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatConversationTime(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(local.year, local.month, local.day);
  final diff = today.difference(messageDay).inDays;

  if (diff == 0) {
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
  if (diff == 1) {
    return 'Yesterday';
  }
  if (diff < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[local.weekday - 1];
  }
  return '${local.month}/${local.day}';
}
