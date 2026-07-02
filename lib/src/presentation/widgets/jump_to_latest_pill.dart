import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

class JumpToLatestPill extends StatelessWidget {
  const JumpToLatestPill({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final theme = chatThemeOf(context);
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          color: theme.pillColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                count == 1 ? '1 new message' : '$count new messages',
                style: TextStyle(
                  color: theme.pillTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
