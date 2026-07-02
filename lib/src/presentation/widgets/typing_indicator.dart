import 'package:flutter/material.dart';

import '../../domain/models/profile.dart';
import '../theme/chat_theme.dart';
import 'profile_avatar.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    super.key,
    required this.typingProfileIds,
    required this.profiles,
  });

  final List<String> typingProfileIds;
  final Map<String, ChatProfile> profiles;

  @override
  Widget build(BuildContext context) {
    if (typingProfileIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = chatThemeOf(context);
    final names = typingProfileIds
        .map((id) => profiles[id]?.name ?? 'Someone')
        .toList();

    final label = switch (names.length) {
      1 => '${names.first} is typing…',
      2 => '${names[0]} and ${names[1]} are typing…',
      _ => '${names.length} people are typing…',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          if (typingProfileIds.length == 1)
            ProfileAvatar(
              profile: profiles[typingProfileIds.first] ?? unknownProfile,
              radius: 10,
            ),
          if (typingProfileIds.length == 1) const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.subtleTextColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
