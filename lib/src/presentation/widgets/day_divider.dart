import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';
import '../utils/message_list_builder.dart';

class DayDivider extends StatelessWidget {
  const DayDivider({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formatDayDivider(day),
            style: TextStyle(
              color: theme.subtleTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
