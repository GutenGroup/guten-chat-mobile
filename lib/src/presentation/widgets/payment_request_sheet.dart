import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cubit/conversation_cubit.dart';
import '../theme/chat_theme.dart';

/// Modal sheet to create an in-chat payment request (display-only on mobile).
class PaymentRequestSheet extends StatefulWidget {
  const PaymentRequestSheet({
    super.key,
    required this.cubit,
  });

  final ConversationCubit cubit;

  static Future<void> show(
    BuildContext context, {
    required ConversationCubit cubit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: chatThemeOf(context).backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: PaymentRequestSheet(cubit: cubit),
      ),
    );
  }

  @override
  State<PaymentRequestSheet> createState() => _PaymentRequestSheetState();
}

class _PaymentRequestSheetState extends State<PaymentRequestSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  var _isSubmitting = false;
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parseAmountCents() {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      return null;
    }
    return (value * 100).round();
  }

  bool get _canSubmit {
    if (_isSubmitting) {
      return false;
    }
    return _parseAmountCents() != null;
  }

  Future<void> _submit() async {
    final amountCents = _parseAmountCents();
    if (amountCents == null) {
      setState(() => _amountError = 'Enter an amount greater than \$0');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _amountError = null;
    });

    HapticFeedback.lightImpact();
    final note = _noteController.text.trim();
    await widget.cubit.createPaymentRequest(
      amountCents: amountCents,
      currency: 'USD',
      note: note.isEmpty ? null : note,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request payment',
              style: TextStyle(
                color: theme.inkColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'USD only — paying stays on web',
              style: TextStyle(
                color: theme.subtleTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                errorText: _amountError,
                filled: true,
                fillColor: theme.dividerColor.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _amountError = null;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                filled: true,
                fillColor: theme.dividerColor.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.accentColor,
                foregroundColor: theme.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.isDark ? Colors.black : Colors.white,
                      ),
                    )
                  : const Text(
                      'Send request',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
