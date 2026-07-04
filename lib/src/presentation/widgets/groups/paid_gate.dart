import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/models/invite_attachment.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../theme/chat_theme.dart';
import '../attachments/html_document_card.dart';
import '../attachments/pdf_document_card.dart';

/// Join gate for paid communities — shown instead of the message list when the
/// viewer has not yet paid (`paid_status != active`).
class PaidGate extends StatefulWidget {
  const PaidGate({
    super.key,
    required this.conversation,
    required this.repository,
    this.onJoinPaidCommunity,
    this.onJoined,
  });

  final Conversation conversation;
  final ChatRepository repository;
  final JoinPaidCommunityHandler? onJoinPaidCommunity;
  final VoidCallback? onJoined;

  @override
  State<PaidGate> createState() => _PaidGateState();
}

class _PaidGateState extends State<PaidGate> {
  var _isJoining = false;
  String? _joinError;

  String get _joinButtonLabel {
    final conversation = widget.conversation;
    if (widget.onJoinPaidCommunity == null) {
      return 'Not available yet';
    }
    return 'Join for ${conversation.joinPriceLabel}';
  }

  Future<void> _handleJoin() async {
    final handler = widget.onJoinPaidCommunity;
    if (handler == null || _isJoining) {
      return;
    }

    setState(() {
      _isJoining = true;
      _joinError = null;
    });

    try {
      final joined = await handler(widget.conversation.id);
      if (!mounted) {
        return;
      }
      if (joined) {
        widget.onJoined?.call();
      } else {
        setState(() {
          _joinError = "Couldn't start checkout. Try again.";
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _joinError = "Couldn't start checkout. Try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final conversation = widget.conversation;
    final title = conversation.title ?? 'Community';

    return ColoredBox(
      color: theme.backgroundColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.inkColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (conversation.description != null &&
              conversation.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              conversation.description!.trim(),
              style: TextStyle(
                color: theme.subtleTextColor,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
          if (conversation.inviteMessage != null &&
              conversation.inviteMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _InviteMessageBlock(message: conversation.inviteMessage!.trim()),
          ],
          if (conversation.inviteAttachment != null) ...[
            const SizedBox(height: 20),
            _InviteAttachmentPreview(
              attachment: conversation.inviteAttachment!,
              repository: widget.repository,
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onJoinPaidCommunity == null || _isJoining
                  ? null
                  : _handleJoin,
              style: FilledButton.styleFrom(
                backgroundColor: theme.paidAccentColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor:
                    theme.surfaceColor.withValues(alpha: 0.9),
                disabledForegroundColor: theme.subtleTextColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      _joinButtonLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          if (_joinError != null) ...[
            const SizedBox(height: 12),
            Text(
              _joinError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.subtleTextColor, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteMessageBlock extends StatelessWidget {
  const _InviteMessageBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.paidAccentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal invite',
            style: TextStyle(
              color: theme.paidAccentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: theme.inkColor,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteAttachmentPreview extends StatelessWidget {
  const _InviteAttachmentPreview({
    required this.attachment,
    required this.repository,
  });

  final InviteAttachment attachment;
  final ChatRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: repository.downloadAttachmentBytes(attachment.path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final bytes = snapshot.data!;
        if (attachment.isHtml) {
          return HtmlDocumentCard(
            title: attachment.name,
            html: utf8.decode(bytes, allowMalformed: true),
          );
        }
        if (attachment.isPdf) {
          return PdfDocumentCard(
            title: attachment.name,
            bytes: Uint8List.fromList(bytes),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
