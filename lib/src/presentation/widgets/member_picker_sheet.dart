import 'package:flutter/material.dart';

import '../../domain/models/participant.dart';
import '../../domain/models/profile.dart';
import '../theme/chat_theme.dart';
import 'profile_avatar.dart';

/// Simple member picker for group tipping — excludes the current user.
class MemberPickerSheet extends StatelessWidget {
  const MemberPickerSheet({
    super.key,
    required this.participants,
    required this.profiles,
    required this.currentProfileId,
    required this.onSelect,
    this.title = 'Send tip to',
  });

  final List<Participant> participants;
  final Map<String, ChatProfile> profiles;
  final String currentProfileId;
  final void Function(String profileId) onSelect;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required List<Participant> participants,
    required Map<String, ChatProfile> profiles,
    required String currentProfileId,
    required void Function(String profileId) onSelect,
    String title = 'Send tip to',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: chatThemeOf(context).surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MemberPickerSheet(
        participants: participants,
        profiles: profiles,
        currentProfileId: currentProfileId,
        onSelect: onSelect,
        title: title,
      ),
    );
  }

  List<Participant> get _others => participants
      .where((p) => p.profileId != currentProfileId)
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final others = _others;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: theme.inkColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          for (var i = 0; i < others.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            _MemberRow(
              profile: profiles[others[i].profileId] ??
                  ChatProfile(name: others[i].profileId),
              onTap: () {
                Navigator.pop(context);
                onSelect(others[i].profileId);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.profile,
    required this.onTap,
  });

  final ChatProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              ProfileAvatar(profile: profile, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile.name,
                  style: TextStyle(
                    color: theme.inkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
