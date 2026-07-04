import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../cubit/inbox_cubit.dart';
import '../../theme/chat_theme.dart';
import '../groups/group_icon_mark.dart';
import '../groups/group_icon_picker.dart';

/// Communities tab — free or paid groups with feed + chat + library (Phase 2).
class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({
    super.key,
    required this.onCommunityTap,
    required this.repository,
    this.onCreateCommunity,
    this.onUploadGroupIcon,
  });

  final ValueChanged<Conversation> onCommunityTap;
  final ChatRepository repository;
  final VoidCallback? onCreateCommunity;
  final GroupIconUploadCallback? onUploadGroupIcon;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        final communities = state.conversations
            .where((c) => c.isGroup)
            .toList();

        return ColoredBox(
          color: theme.backgroundColor,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.backgroundColor,
                title: Text(
                  'Communities',
                  style: TextStyle(
                    color: theme.inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  if (onCreateCommunity != null)
                    IconButton(
                      icon: Icon(Icons.add, color: theme.inkColor),
                      onPressed: onCreateCommunity,
                      tooltip: 'New community',
                    ),
                ],
              ),
              if (state.isLoading && communities.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (communities.isEmpty)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_outlined,
                            size: 48, color: theme.subtleTextColor),
                        const SizedBox(height: 12),
                        Text(
                          'No communities yet',
                          style: TextStyle(
                            color: theme.inkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Communities are rich spaces with a feed, chat, and '
                          'library. Create one to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.subtleTextColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phase 2: full feed + library UI lands next. '
                          'Backend: `chat_community_feed` (planned).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.subtleTextColor,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final community = communities[index];
                      final profile = community.createdByProfileId != null
                          ? state.profileNames[
                              community.createdByProfileId!]
                          : null;
                      return _CommunityTile(
                        community: community,
                        profile: profile,
                        onTap: () => onCommunityTap(community),
                      );
                    },
                    childCount: communities.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({
    required this.community,
    required this.profile,
    required this.onTap,
  });

  final Conversation community;
  final ChatProfile? profile;
  final VoidCallback onTap;

  String get _priceLabel {
    if (!community.isPaid) {
      return 'Free';
    }
    return community.formattedPrice;
  }

  String get _subtitle {
    if (community.isPaidInvitePending) {
      return 'Invitation · tap to join';
    }
    return 'Feed · Library · Chat · Resources';
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final title = community.title ?? profile?.name ?? 'Community';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GroupAvatar(
              title: title,
              imageUrl: community.imageUrl,
              markId: GroupIconMarkId.hexagon,
              radius: 26,
              backgroundColor: theme.surfaceColor,
              foregroundColor: theme.inkColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.inkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (community.isPaid)
                        Text(
                          _priceLabel,
                          style: TextStyle(
                            color: theme.paidAccentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          _priceLabel,
                          style: TextStyle(
                            color: theme.subtleTextColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      color: community.isPaidInvitePending
                          ? theme.paidAccentColor
                          : theme.subtleTextColor,
                      fontSize: 13,
                      fontWeight: community.isPaidInvitePending
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (community.lastMessagePreview != null &&
                      community.lastMessagePreview!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        community.lastMessagePreview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.subtleTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (community.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.inkColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${community.unreadCount}',
                  style: TextStyle(
                    color: theme.backgroundColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
