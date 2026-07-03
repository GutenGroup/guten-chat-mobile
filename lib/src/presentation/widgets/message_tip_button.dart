import 'package:flutter/material.dart';

import '../../domain/models/tip_presets.dart';
import 'expandable_icon_menu.dart';

class MessageTipButton extends StatelessWidget {
  const MessageTipButton({
    super.key,
    required this.onTipSelected,
    this.amountsCents = TipPresets.amountCents,
    this.currency = TipPresets.currency,
  });

  final void Function(int amountCents, String currency) onTipSelected;
  final List<int> amountsCents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return ExpandableIconMenu(
      triggerIcon: Icons.volunteer_activism_outlined,
      triggerSize: 36,
      pillSize: 40,
      pitch: 48,
      baseOffset: 48,
      alignment: ExpandableMenuAlignment.bottomLeft,
      choices: [
        for (final amount in amountsCents)
          ExpandableMenuChoice(
            icon: Icons.volunteer_activism_outlined,
            label: TipPresets.formatAmount(amount, currencyCode: currency),
            onTap: () => onTipSelected(amount, currency),
          ),
      ],
    );
  }
}

/// Compact inline tip trigger shown beside received bubbles.
class MessageTipAffordance extends StatelessWidget {
  const MessageTipAffordance({
    super.key,
    required this.onTipSelected,
  });

  final void Function(int amountCents, String currency) onTipSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 18),
      child: MessageTipButton(onTipSelected: onTipSelected),
    );
  }
}
