import 'package:flutter/material.dart';

import '../../domain/models/payment_request.dart';
import '../../domain/models/tip_presets.dart';
import '../theme/chat_theme.dart';

/// Inline payment-request card — display + status only (no native pay rail).
class PaymentRequestCard extends StatelessWidget {
  const PaymentRequestCard({
    super.key,
    required this.paymentRequest,
    required this.requesterName,
  });

  final PaymentRequest paymentRequest;
  final String requesterName;

  static String statusLabel(PaymentRequestStatus status) {
    switch (status) {
      case PaymentRequestStatus.paid:
        return 'Paid';
      case PaymentRequestStatus.cancelled:
        return 'Canceled';
      case PaymentRequestStatus.expired:
        return 'Expired';
      case PaymentRequestStatus.pending:
        return 'Open';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final amount = TipPresets.formatAmount(
      paymentRequest.amountCents,
      currencyCode: paymentRequest.currency,
    );

    // v0.5.0: cards hug their content (min 240 / max 320) instead of
    // stretching across the thread; subtle accent-tinted surface
    // (accent 7% over raised) with an accent 32% hairline — tokens.json
    // semantics, value-matched to the web .gc-pay-card.
    final cardBg = Color.alphaBlend(
      theme.accentColor.withValues(alpha: 0.07),
      theme.surfaceColor,
    );

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.accentColor.withValues(alpha: 0.32)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    color: theme.accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      amount,
                      style: TextStyle(
                        color: theme.inkColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Requested by $requesterName',
                style: TextStyle(
                  color: theme.subtleTextColor,
                  fontSize: 12,
                ),
              ),
              if (paymentRequest.note != null &&
                  paymentRequest.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  paymentRequest.note!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.inkColor.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                statusLabel(paymentRequest.status),
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 12,
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
