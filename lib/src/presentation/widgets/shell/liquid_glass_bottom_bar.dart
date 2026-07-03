import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';

enum GutenChatTab {
  updates,
  chats,
  communities,
  profile,
}

class LiquidGlassBottomBar extends StatelessWidget {
  const LiquidGlassBottomBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.profileInitials = '?',
  });

  final GutenChatTab selected;
  final ValueChanged<GutenChatTab> onSelected;
  final String profileInitials;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.bottomBarColor,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, bottom > 0 ? bottom : 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabButton(
                  label: 'Updates',
                  icon: Icons.dynamic_feed_outlined,
                  selectedIcon: Icons.dynamic_feed,
                  isSelected: selected == GutenChatTab.updates,
                  onTap: () => onSelected(GutenChatTab.updates),
                ),
                _TabButton(
                  label: 'Chats',
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  isSelected: selected == GutenChatTab.chats,
                  onTap: () => onSelected(GutenChatTab.chats),
                ),
                _TabButton(
                  label: 'Communities',
                  icon: Icons.groups_outlined,
                  selectedIcon: Icons.groups,
                  isSelected: selected == GutenChatTab.communities,
                  onTap: () => onSelected(GutenChatTab.communities),
                ),
                _ProfileTabButton(
                  label: 'Profile',
                  initials: profileInitials,
                  isSelected: selected == GutenChatTab.profile,
                  onTap: () => onSelected(GutenChatTab.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final color = isSelected ? theme.inkColor : theme.subtleTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    required this.label,
    required this.initials,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String initials;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final color = isSelected ? theme.inkColor : theme.subtleTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isSelected
                  ? theme.inkColor
                  : theme.surfaceColor,
              child: Text(
                initials,
                style: TextStyle(
                  color: isSelected
                      ? theme.backgroundColor
                      : theme.subtleTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
