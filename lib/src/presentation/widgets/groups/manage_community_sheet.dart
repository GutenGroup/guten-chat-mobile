import 'package:flutter/material.dart';

import '../../../domain/models/chat_features.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/models/participant.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../theme/chat_theme.dart';

/// Per-member role actions in a bottom sheet menu — no horizontal overflow.
class ManageCommunitySheet extends StatelessWidget {
  const ManageCommunitySheet({
    super.key,
    required this.conversation,
    required this.participants,
    required this.profiles,
    required this.currentProfileId,
    required this.features,
    required this.repository,
    this.onUpdated,
  });

  final Conversation conversation;
  final List<Participant> participants;
  final Map<String, ChatProfile> profiles;
  final String currentProfileId;
  final ChatFeatures features;
  final ChatRepository repository;
  final VoidCallback? onUpdated;

  static Future<void> show(
    BuildContext context, {
    required Conversation conversation,
    required List<Participant> participants,
    required Map<String, ChatProfile> profiles,
    required String currentProfileId,
    required ChatFeatures features,
    required ChatRepository repository,
    VoidCallback? onUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: chatThemeOf(context).backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ManageCommunitySheet(
          conversation: conversation,
          participants: participants,
          profiles: profiles,
          currentProfileId: currentProfileId,
          features: features,
          repository: repository,
          onUpdated: onUpdated,
        ),
      ),
    );
  }

  Participant? get _currentParticipant {
    for (final p in participants) {
      if (p.profileId == currentProfileId) {
        return p;
      }
    }
    return null;
  }

  bool _canManageRoles(ParticipantRole role) {
    return role == ParticipantRole.owner || role == ParticipantRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final current = _currentParticipant;
    final canManage = current != null && _canManageRoles(current.role);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage community',
                  style: TextStyle(
                    color: theme.inkColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Members · ${participants.length}',
                  style: TextStyle(color: theme.subtleTextColor, fontSize: 14),
                ),
              ],
            ),
          ),
          if (features.tipping) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.volunteer_activism_outlined,
                    color: theme.inkColor),
                title: Text(
                  'Tipping',
                  style: TextStyle(
                    color: theme.inkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Let members send tips here',
                  style: TextStyle(color: theme.subtleTextColor),
                ),
              ),
            ),
            if (features.paymentRequests)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.account_balance_wallet_outlined,
                          color: theme.inkColor),
                  title: Text(
                    'Receive payouts',
                    style: TextStyle(
                      color: theme.inkColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Set up where tips and payments land',
                    style: TextStyle(color: theme.subtleTextColor),
                  ),
                  trailing: Icon(Icons.chevron_right, color: theme.subtleTextColor),
                  onTap: () {},
                ),
              ),
            Divider(color: theme.dividerColor, height: 24),
          ],
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: participants.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: theme.dividerColor, indent: 72),
              itemBuilder: (context, index) {
                final participant = participants[index];
                final profile =
                    profiles[participant.profileId] ?? unknownProfile;
                final isSelf = participant.profileId == currentProfileId;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.surfaceColor,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(color: theme.inkColor),
                    ),
                  ),
                  title: Text(
                    isSelf ? '${profile.name} (you)' : profile.name,
                    style: TextStyle(
                      color: theme.inkColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _roleLabel(participant.role, conversation.isPaid),
                    style: TextStyle(
                      color: participant.role == ParticipantRole.owner &&
                              conversation.isPaid
                          ? theme.paidAccentColor
                          : theme.subtleTextColor,
                    ),
                  ),
                  trailing: canManage && !isSelf
                      ? IconButton(
                          icon: Icon(Icons.more_horiz, color: theme.inkColor),
                          onPressed: () => _showMemberMenu(
                            context,
                            participant: participant,
                            profile: profile,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(ParticipantRole role, bool isPaid) {
    return switch (role) {
      ParticipantRole.owner => isPaid ? '♛ Owner' : 'Owner',
      ParticipantRole.admin => 'Admin',
      ParticipantRole.moderator => '⛨ Moderator',
      ParticipantRole.member => 'Member',
    };
  }

  Future<void> _showMemberMenu(
    BuildContext context, {
    required Participant participant,
    required ChatProfile profile,
  }) async {
    final theme = chatThemeOf(context);
    final current = _currentParticipant;
    if (current == null) {
      return;
    }

    final actions = <Widget>[];

    if (features.moderatorRole &&
        current.role.canModerate &&
        participant.role == ParticipantRole.member) {
      actions.add(
        ListTile(
          leading: Icon(Icons.shield_outlined, color: theme.inkColor),
          title: Text('Make moderator', style: TextStyle(color: theme.inkColor)),
          onTap: () async {
            Navigator.pop(context);
            await repository.setGroupRole(
              conversation.id,
              participant.profileId,
              ParticipantRole.moderator,
            );
            onUpdated?.call();
          },
        ),
      );
    }

    if (current.role == ParticipantRole.owner &&
        participant.role != ParticipantRole.admin) {
      actions.add(
        ListTile(
          leading: Icon(Icons.admin_panel_settings_outlined,
              color: theme.inkColor),
          title: Text('Make admin', style: TextStyle(color: theme.inkColor)),
          onTap: () async {
            Navigator.pop(context);
            await repository.setGroupRole(
              conversation.id,
              participant.profileId,
              ParticipantRole.admin,
            );
            onUpdated?.call();
          },
        ),
      );
    }

    if (current.role.canModerate &&
        participant.role != ParticipantRole.member) {
      actions.add(
        ListTile(
          leading: Icon(Icons.person_outline, color: theme.inkColor),
          title: Text('Make member', style: TextStyle(color: theme.inkColor)),
          onTap: () async {
            Navigator.pop(context);
            await repository.setGroupRole(
              conversation.id,
              participant.profileId,
              ParticipantRole.member,
            );
            onUpdated?.call();
          },
        ),
      );
    }

    if (current.role.canModerate) {
      actions.add(
        ListTile(
          leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
          title: const Text('Remove from community',
              style: TextStyle(color: Colors.red)),
          onTap: () async {
            Navigator.pop(context);
            await repository.removeGroupMember(
              conversation.id,
              participant.profileId,
            );
            onUpdated?.call();
          },
        ),
      );
    }

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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                profile.name,
                style: TextStyle(
                  color: theme.inkColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ...actions,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
