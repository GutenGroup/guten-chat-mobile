import 'package:flutter/material.dart';

import '../../domain/models/conversation.dart';
import '../theme/chat_theme.dart';
import 'groups/group_icon_mark.dart';

/// Thread header — title + icon only (no member subtitle).
class ConversationHeader extends StatelessWidget implements PreferredSizeWidget {
  const ConversationHeader({
    super.key,
    required this.title,
    this.conversation,
    this.onBack,
    this.onManage,
    this.isOnline = false,
  });

  final String title;
  final Conversation? conversation;
  final VoidCallback? onBack;
  final VoidCallback? onManage;
  final bool isOnline;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return AppBar(
      leading: onBack != null
          ? BackButton(onPressed: onBack, color: theme.inkColor)
          : null,
      title: Row(
        children: [
          GroupAvatar(
            title: title,
            imageUrl: conversation?.imageUrl,
            markId: conversation?.isGroup == true
                ? GroupIconMarkId.monogram
                : null,
            radius: 16,
            backgroundColor: theme.surfaceColor,
            foregroundColor: theme.inkColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.inkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (isOnline) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onManage != null)
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.inkColor),
            onPressed: onManage,
          ),
      ],
    );
  }
}
