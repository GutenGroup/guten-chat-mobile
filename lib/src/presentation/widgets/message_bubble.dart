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
import 'payment_request_card.dart';
import 'voice_note_attachment_view.dart';
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
    this.bubbleKey,
    this.onOpenContextMenu,
    this.previewOnly = false,
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
  final GlobalKey? bubbleKey;
  final VoidCallback? onOpenContextMenu;
  final bool previewOnly;

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
        // Accent-filled bubble → accent-contrast ink (sentTextColor carries it).
        ? theme.sentTextColor
        : (isOwn ? theme.sentTextColor : theme.receivedTextColor);
    final time = DateFormat.jm().format(message.createdAt.toLocal());
    final summaries = summarizeReactions(
      message.reactions,
      isOwn ? message.senderProfileId : '',
    );

    Future<String> resolveUrl(String storagePath) =>
        repository.createSignedAttachmentUrl(storagePath);

    Future<List<int>> resolveBytes(String storagePath) =>
        repository.downloadAttachmentBytes(storagePath);

    final bubble = MessageBubbleContent(
      message: message,
      isOwn: isOwn,
      isGroupedWithPrevious: isGroupedWithPrevious,
      features: features,
      bubbleColor: bubbleColor,
      textColor: textColor,
      resolveUrl: resolveUrl,
      resolveBytes: resolveBytes,
      onOpenContextMenu: onOpenContextMenu,
      bubbleKey: bubbleKey,
      requesterName: profile.name,
    );

    if (previewOnly) {
      return bubble;
    }

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
                bubble,
                if (features.reactions && summaries.isNotEmpty)
                  // Tuck the cluster up over the bubble's bottom edge so it
                  // reads as anchored to THIS bubble (iMessage/WhatsApp), on
                  // the sender's outside corner. Transform keeps the layout
                  // slot stable so the timestamp below never reflows.
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Wrap(
                        alignment:
                            isOwn ? WrapAlignment.end : WrapAlignment.start,
                        spacing: 4,
                        runSpacing: 4,
                        children: summaries
                            .map((summary) =>
                                _reactionChip(theme, summary, brandMarks))
                            .toList(),
                      ),
                    ),
                  ),
                // Media-only bubbles carry the time as an overlay pill on the
                // image (v0.5.0) — only the read receipt remains down here.
                if (!MessageBubbleContent.isMediaOnly(message) ||
                    (features.readReceipts && isOwn))
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!MessageBubbleContent.isMediaOnly(message))
                          Text(
                            time,
                            style: TextStyle(
                              color: theme.subtleTextColor,
                              fontSize: 11,
                            ),
                          ),
                        if (features.readReceipts && isOwn) ...[
                          if (!MessageBubbleContent.isMediaOnly(message))
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

  /// A single reaction chip: elevated round-ended surface, hairline border and
  /// a soft lift so it floats above the bubble in the black theme. The count is
  /// secondary and shown only when 2+ react (a lone reaction is just the glyph
  /// in a round chip) — visually matched to the web `.gc-pill`.
  Widget _reactionChip(
    ChatTheme theme,
    ReactionSummary summary,
    List<BrandReactionMark> brandMarks,
  ) {
    final mine = summary.includesMe;
    final showCount = summary.count > 1;
    final label = _reactionLabel(summary, brandMarks);
    final chipBg = theme.isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.07), theme.pillColor)
        : Colors.white;
    final background = mine
        ? Color.alphaBlend(theme.accentColor.withValues(alpha: 0.16), chipBg)
        : chipBg;
    return GestureDetector(
      onTap: () => onToggleReaction(summary.value, summary.kind),
      child: Container(
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        padding: EdgeInsets.symmetric(
          horizontal: showCount ? 8 : 5,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: mine
                ? theme.accentColor.withValues(alpha: 0.55)
                : theme.dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.isDark ? 0.45 : 0.16),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, height: 1.0)),
            if (showCount) ...[
              const SizedBox(width: 4),
              Text(
                '${summary.count}',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: FontWeight.w600,
                  color: mine ? theme.accentColor : theme.subtleTextColor,
                ),
              ),
            ],
          ],
        ),
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
}

/// Bubble body used in-thread and in the context-menu overlay preview.
class MessageBubbleContent extends StatelessWidget {
  const MessageBubbleContent({
    super.key,
    required this.message,
    required this.isOwn,
    required this.isGroupedWithPrevious,
    required this.features,
    required this.bubbleColor,
    required this.textColor,
    required this.resolveUrl,
    required this.resolveBytes,
    this.bubbleKey,
    this.onOpenContextMenu,
    this.requesterName,
  });

  final Message message;
  final bool isOwn;
  final bool isGroupedWithPrevious;
  final ChatFeatures features;
  final Color bubbleColor;
  final Color textColor;
  final Future<String> Function(String storagePath) resolveUrl;
  final Future<List<int>> Function(String storagePath) resolveBytes;
  final GlobalKey? bubbleKey;
  final VoidCallback? onOpenContextMenu;
  final String? requesterName;

  /// v0.5.0 media bubble: an image-only message renders as a thin raised tile
  /// (so transparent logos/stickers still read as sent) with the timestamp
  /// overlaid on the image — web `.gc-bubble--media` parity.
  static bool isMediaOnly(Message message) {
    return !message.isDeleted &&
        !message.isSystem &&
        message.body.isEmpty &&
        message.paymentRequest == null &&
        message.replyPreview == null &&
        message.attachments.length == 1 &&
        message.attachments.first.kind == AttachmentKind.image;
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final canOpenMenu =
        onOpenContextMenu != null && !message.isSystem && !message.isDeleted;

    if (message.isDeleted) {
      return Container(
        key: bubbleKey,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        child: Text(
          'Message deleted',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.65),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (isMediaOnly(message)) {
      final time = DateFormat.jm().format(message.createdAt.toLocal());
      final maxTileWidth = MediaQuery.sizeOf(context).width * 0.78;
      final uploading = message.uploadProgress != null &&
          message.status == MessageStatus.sending;
      return GestureDetector(
        onTap: canOpenMenu ? onOpenContextMenu : null,
        onLongPress: canOpenMenu ? onOpenContextMenu : null,
        child: Container(
          key: bubbleKey,
          // Image caps at 320 wide (web) + 3px tile padding + hairline.
          constraints: BoxConstraints(
            maxWidth: maxTileWidth < 328 ? maxTileWidth : 328,
          ),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ImageAttachmentView(
                    attachment: message.attachments.first,
                    resolveUrl: resolveUrl,
                    maxHeight: 420,
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (uploading)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
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
      );
    }

    return GestureDetector(
      onTap: canOpenMenu ? onOpenContextMenu : null,
      onLongPress: canOpenMenu ? onOpenContextMenu : null,
      child: Container(
        key: bubbleKey,
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
              isOwn || isGroupedWithPrevious ? theme.borderRadius : 4,
            ),
            bottomRight: Radius.circular(
              !isOwn || isGroupedWithPrevious ? theme.borderRadius : 4,
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
            ..._buildAttachmentContent(context),
            if (message.paymentRequest != null)
              Padding(
                padding: EdgeInsets.only(
                  bottom: message.body.isNotEmpty && !message.hasPaymentRequest
                      ? 8
                      : 0,
                ),
                child: PaymentRequestCard(
                  paymentRequest: message.paymentRequest!,
                  requesterName: requesterName ?? 'Unknown',
                ),
              ),
            if (message.body.isNotEmpty && !message.hasPaymentRequest)
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
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.4),
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
    );
  }

  List<Widget> _buildAttachmentContent(BuildContext context) {
    if (!message.hasAttachments) {
      return const [];
    }

    return [
      for (final attachment in message.attachments) ...[
        Padding(
          padding: EdgeInsets.only(bottom: message.body.isNotEmpty ? 8 : 0),
          child: _buildAttachment(context: context, attachment: attachment),
        ),
      ],
    ];
  }

  Widget _buildAttachment({
    required BuildContext context,
    required MessageAttachment attachment,
  }) {
    if (attachment.kind == AttachmentKind.image) {
      return ImageAttachmentView(
        attachment: attachment,
        resolveUrl: resolveUrl,
      );
    }

    if (attachment.kind == AttachmentKind.voiceNote) {
      return VoiceNoteAttachmentView(
        attachment: attachment,
        resolveUrl: resolveUrl,
        // v0.5.0: the player inks from the bubble it sits in.
        ink: textColor,
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
