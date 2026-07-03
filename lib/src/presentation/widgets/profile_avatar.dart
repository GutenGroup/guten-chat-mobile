import 'package:flutter/material.dart';

import '../../domain/models/profile.dart';
import '../theme/chat_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.radius = 18,
  });

  final ChatProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final url = profile.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        backgroundColor: theme.dividerColor,
      );
    }

    final initial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.surfaceColor,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.inkColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
