import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/models/conversation.dart';
import '../../domain/models/profile.dart';
import '../cubit/inbox_cubit.dart';
import '../theme/chat_theme.dart';
import 'profile_avatar.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({
    super.key,
    required this.onConversationTap,
  });

  final ValueChanged<Conversation> onConversationTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        if (state.isLoading && state.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.conversations.isEmpty) {
          return Center(
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
          );
        }

        if (state.conversations.isEmpty) {
          return Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(color: theme.subtleTextColor),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<InboxCubit>().load(),
          child: ListView.separated(
            itemCount: state.conversations.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, index) {
              final conversation = state.conversations[index];
              final profile = conversation.createdByProfileId != null
                  ? state.profileNames[conversation.createdByProfileId!]
                  : null;
              return _InboxTile(
                conversation: conversation,
                profile: profile,
                onTap: () => onConversationTap(conversation),
              );
            },
          ),
        );
      },
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
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
    final time = conversation.lastMessageAt != null
        ? DateFormat.MMMd().add_jm().format(
              conversation.lastMessageAt!.toLocal(),
            )
        : '';

    return ListTile(
      onTap: onTap,
      leading: ProfileAvatar(profile: profile ?? unknownProfile),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.subtleTextColor),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(color: theme.subtleTextColor, fontSize: 12),
            ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 10,
              backgroundColor: theme.primaryColor,
              child: Text(
                '${conversation.unreadCount}',
                style: TextStyle(
                  color: theme.pillTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
