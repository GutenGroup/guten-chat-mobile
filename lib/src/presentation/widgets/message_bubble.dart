import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_attachment.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/reaction.dart';
import '../../domain/repositories/chat_repository.dart';
import '../theme/chat_theme.dart';
import 'attachments/attachment_views.dart';
import 'attachments/html_attachment_loader.dart';
import 'attachments/pdf_attachment_loader.dart';
import 'message_tip_button.dart';
import 'profile_avatar.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.showAvatar,
    required this.isGroupedWithPrevious,
    required this.profile,
    required this.features,
    required this.isGroup,
    required this.seenCount,
    required this.onReply,
    required this.onToggleReaction,
    required this.brandMarks,
    required this.repository,
    this.onSendTip,
  });

  final Message message;
  final bool isOwn;
  final bool showAvatar;
  final bool isGroupedWithPrevious;
  final ChatProfile profile;
  final ChatFeatures features;
  final bool isGroup;
  final int seenCount;
  final VoidCallback onReply;
  final void Function(String value, ReactionKind kind) onToggleReaction;
  final List<BrandReactionMark> brandMarks;
  final ChatRepository repository;
  final void Function(int amountCents, String currency)? onSendTip;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final isEmphasized = message.reactions.any(
      (r) => r.kind == ReactionKind.brand,
    );
    final bubbleColor = isEmphasized
        ? theme.accentColor
        : (isOwn ? theme.sentBubbleColor : theme.receivedBubbleColor);
    final textColor = isEmphasized
        ? (theme.isDark ? Colors.black : Colors.white)
        : (isOwn ? theme.sentTextColor : theme.receivedTextColor);
    final time = DateFormat.jm().format(message.createdAt.toLocal());
    final summaries = summarizeReactions(
      message.reactions,
      isOwn ? message.senderProfileId : '',
    );
    final showTipAffordance =
        features.tipping && !isOwn && onSendTip != null && !message.isSystem;

    Future<String> resolveUrl(String storagePath) =>
        repository.createSignedAttachmentUrl(storagePath);

    Future<List<int>> resolveBytes(String storagePath) =>
        repository.downloadAttachmentBytes(storagePath);

    return Padding(
      padding: EdgeInsets.only(
        top: isGroupedWithPrevious ? 2 : 8,
        left: 12,
        right: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwn && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ProfileAvatar(profile: profile, radius: 14),
            )
          else if (!isOwn)
            const SizedBox(width: 36),
          if (showTipAffordance)
            MessageTipAffordance(
              onTipSelected: (amount, currency) =>
                  onSendTip!(amount, currency),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwn && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      profile.name,
                      style: TextStyle(
                        color: theme.subtleTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: features.replies ? onReply : null,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(theme.borderRadius),
                        topRight: Radius.circular(theme.borderRadius),
                        bottomLeft: Radius.circular(
                          isOwn || isGroupedWithPrevious
                              ? theme.borderRadius
                              : 4,
                        ),
                        bottomRight: Radius.circular(
                          !isOwn || isGroupedWithPrevious
                              ? theme.borderRadius
                              : 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyPreview != null && features.replies)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isOwn ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message.replyPreview!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ..._buildAttachmentContent(
                          context: context,
                          resolveUrl: resolveUrl,
                          resolveBytes: resolveBytes,
                        ),
                        if (message.body.isNotEmpty)
                          Text(
                            message.body,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        if (message.uploadProgress != null &&
                            message.status == MessageStatus.sending)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(
                              value: message.uploadProgress,
                              minHeight: 3,
                              color: theme.accentColor,
                              backgroundColor:
                                  theme.dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                        if (message.isFailed)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Failed to send',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (features.reactions && summaries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: summaries.map((summary) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '${_reactionLabel(summary, brandMarks)} ${summary.count}',
                          ),
                          backgroundColor: summary.includesMe
                              ? theme.accentColor.withValues(alpha: 0.12)
                              : theme.surfaceColor,
                          onPressed: () => onToggleReaction(
                            summary.value,
                            summary.kind,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: theme.subtleTextColor,
                          fontSize: 11,
                        ),
                      ),
                      if (features.readReceipts && isOwn) ...[
                        const SizedBox(width: 4),
                        _ReadReceiptIcon(
                          isGroup: isGroup,
                          seenCount: seenCount,
                          isSending: message.status == MessageStatus.sending,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reactionLabel(
    ReactionSummary summary,
    List<BrandReactionMark> brandMarks,
  ) {
    if (summary.kind == ReactionKind.emoji) {
      return summary.value;
    }
    return brandMarks
            .where((mark) => mark.id == summary.value)
            .map((mark) => mark.emojiFallback)
            .firstOrNull ??
        '★';
  }

  List<Widget> _buildAttachmentContent({
    required BuildContext context,
    required Future<String> Function(String storagePath) resolveUrl,
    required Future<List<int>> Function(String storagePath) resolveBytes,
  }) {
    if (!message.hasAttachments) {
      return const [];
    }

    return [
      for (final attachment in message.attachments) ...[
        Padding(
          padding: EdgeInsets.only(bottom: message.body.isNotEmpty ? 8 : 0),
          child: _buildAttachment(
            context: context,
            attachment: attachment,
            resolveUrl: resolveUrl,
            resolveBytes: resolveBytes,
          ),
        ),
      ],
    ];
  }

  Widget _buildAttachment({
    required BuildContext context,
    required MessageAttachment attachment,
    required Future<String> Function(String storagePath) resolveUrl,
    required Future<List<int>> Function(String storagePath) resolveBytes,
  }) {
    if (attachment.kind == AttachmentKind.image) {
      return ImageAttachmentView(
        attachment: attachment,
        resolveUrl: resolveUrl,
      );
    }

    if (attachment.isHtml) {
      return HtmlAttachmentLoader(
        attachment: attachment,
        resolveBytes: resolveBytes,
      );
    }

    if (attachment.isPdf) {
      return PdfAttachmentLoader(
        attachment: attachment,
        resolveBytes: resolveBytes,
      );
    }

    return FileAttachmentChip(
      attachment: attachment,
      onTap: () => openAttachment(
        context: context,
        attachment: attachment,
        resolveBytes: resolveBytes,
        resolveUrl: resolveUrl,
      ),
    );
  }
}

class _ReadReceiptIcon extends StatelessWidget {
  const _ReadReceiptIcon({
    required this.isGroup,
    required this.seenCount,
    required this.isSending,
  });

  final bool isGroup;
  final int seenCount;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    if (isSending) {
      return Icon(Icons.access_time, size: 12, color: theme.subtleTextColor);
    }

    if (isGroup) {
      if (seenCount <= 0) {
        return Icon(Icons.check, size: 14, color: theme.subtleTextColor);
      }
      return Text(
        'Seen by $seenCount',
        style: TextStyle(color: theme.subtleTextColor, fontSize: 10),
      );
    }

    return Icon(
      seenCount > 0 ? Icons.done_all : Icons.check,
      size: 14,
      color: seenCount > 0 ? theme.accentColor : theme.subtleTextColor,
    );
  }
}
