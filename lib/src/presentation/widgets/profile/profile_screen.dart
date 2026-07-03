import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';

/// Profile / settings tab. Read receipts and active status are always on.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.displayName,
    required this.handle,
    required this.appearance,
    required this.onAppearanceChanged,
    this.avatarInitials = '?',
    this.visibilityLabel = 'Public',
    this.notificationsEnabled = true,
    this.onVisibilityTap,
    this.onNotificationsTap,
    this.onPayoutsTap,
    this.onBlockedTap,
    this.onEditProfile,
  });

  final String displayName;
  final String handle;
  final String avatarInitials;
  final GutenChatAppearance appearance;
  final ValueChanged<GutenChatAppearance> onAppearanceChanged;
  final String visibilityLabel;
  final bool notificationsEnabled;
  final VoidCallback? onVisibilityTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onPayoutsTap;
  final VoidCallback? onBlockedTap;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return ColoredBox(
      color: theme.backgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.backgroundColor,
            title: Text(
              'Profile',
              style: TextStyle(
                color: theme.inkColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onEditProfile,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.surfaceColor,
                      child: Text(
                        avatarInitials,
                        style: TextStyle(
                          color: theme.inkColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: TextStyle(
                      color: theme.inkColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '@$handle · tap to edit',
                    style: TextStyle(color: theme.subtleTextColor),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _SettingsTile(
                icon: Icons.visibility_outlined,
                title: 'Visibility',
                subtitle: visibilityLabel,
                onTap: onVisibilityTap,
              ),
              _AppearanceTile(
                current: appearance,
                onChanged: onAppearanceChanged,
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: notificationsEnabled ? 'On' : 'Off',
                onTap: onNotificationsTap,
              ),
              _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payouts & tips',
                subtitle: 'Set up',
                onTap: onPayoutsTap,
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Blocked & privacy',
                onTap: onBlockedTap,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Read receipts and active status are always on.',
                  style: TextStyle(
                    color: theme.subtleTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(
                  'Mute notifications per chat from the chat menu — not here.',
                  style: TextStyle(
                    color: theme.subtleTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return ListTile(
      leading: Icon(icon, color: theme.inkColor),
      title: Text(
        title,
        style: TextStyle(color: theme.inkColor, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: theme.subtleTextColor))
          : null,
      trailing: Icon(Icons.chevron_right, color: theme.subtleTextColor),
      onTap: onTap,
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({
    required this.current,
    required this.onChanged,
  });

  final GutenChatAppearance current;
  final ValueChanged<GutenChatAppearance> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return ListTile(
      leading: Icon(Icons.brightness_6_outlined, color: theme.inkColor),
      title: Text(
        'Appearance',
        style: TextStyle(color: theme.inkColor, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _label(current),
        style: TextStyle(color: theme.subtleTextColor),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.subtleTextColor),
      onTap: () => _showPicker(context),
    );
  }

  String _label(GutenChatAppearance value) {
    return switch (value) {
      GutenChatAppearance.system => 'System',
      GutenChatAppearance.light => 'Light',
      GutenChatAppearance.dark => 'Dark',
    };
  }

  Future<void> _showPicker(BuildContext context) async {
    final theme = chatThemeOf(context);
    final selected = await showModalBottomSheet<GutenChatAppearance>(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: GutenChatAppearance.values.map((mode) {
            return RadioListTile<GutenChatAppearance>(
              title: Text(_label(mode),
                  style: TextStyle(color: theme.inkColor)),
              value: mode,
              groupValue: current,
              activeColor: theme.accentColor,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}
