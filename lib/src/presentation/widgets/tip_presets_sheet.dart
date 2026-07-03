import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/tip_presets.dart';
import '../theme/chat_theme.dart';

/// Shared tip amount picker — used from composer and context menu.
class TipPresetsSheet extends StatelessWidget {
  const TipPresetsSheet({
    super.key,
    required this.onSelect,
    this.title = 'Tip amount',
  });

  final void Function(int amountCents) onSelect;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required void Function(int amountCents) onSelect,
    String title = 'Tip amount',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: chatThemeOf(context).surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => TipPresetsSheet(
        onSelect: onSelect,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

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
          for (var i = 0; i < TipPresets.amountCents.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            TipPresetAmountRow(
              amountCents: TipPresets.amountCents[i],
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onSelect(TipPresets.amountCents[i]);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class TipPresetAmountRow extends StatelessWidget {
  const TipPresetAmountRow({
    super.key,
    required this.amountCents,
    required this.onTap,
  });

  final int amountCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 20,
                color: theme.accentColor,
              ),
              const SizedBox(width: 12),
              Text(
                TipPresets.formatAmount(amountCents),
                style: TextStyle(
                  color: theme.inkColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
