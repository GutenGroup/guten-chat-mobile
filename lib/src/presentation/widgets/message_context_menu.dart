import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/models/message.dart';
import '../../domain/models/reaction.dart';
import '../../domain/models/tip_presets.dart';
import '../theme/chat_theme.dart';
import 'tip_presets_sheet.dart';

const kQuickReactions = <String>['❤️', '😂', '👍', '‼️', '🙏'];

/// iMessage-class overlay: lifted bubble, reactions bar, action sheet.
class MessageContextMenu {
  MessageContextMenu._();

  static OverlayEntry? _entry;
  static MessageContextMenuOverlayState? _state;

  static bool get isVisible => _entry != null;

  static void show({
    required BuildContext context,
    required Rect anchorRect,
    required Message message,
    required bool isOwn,
    required ChatFeatures features,
    required VoidCallback onDismiss,
    required VoidCallback onReply,
    required void Function(String value, ReactionKind kind) onToggleReaction,
    required VoidCallback onForward,
    required VoidCallback? onDelete,
    required void Function(int amountCents, String currency)? onSendTip,
    required Widget messagePreview,
    List<BrandReactionMark> brandMarks = const [],
  }) {
    dismiss();

    HapticFeedback.mediumImpact();
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _MessageContextMenuOverlay(
        anchorRect: anchorRect,
        message: message,
        isOwn: isOwn,
        features: features,
        brandMarks: brandMarks,
        messagePreview: messagePreview,
        onDismiss: () {
          dismiss();
          onDismiss();
        },
        onReply: () {
          dismiss();
          onReply();
        },
        onToggleReaction: (value, kind) {
          onToggleReaction(value, kind);
        },
        onForward: () {
          dismiss();
          onForward();
        },
        onDelete: onDelete == null
            ? null
            : () {
                dismiss();
                onDelete();
              },
        onSendTip: onSendTip,
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _state?._close();
    _entry?.remove();
    _entry = null;
    _state = null;
  }

  static void registerState(MessageContextMenuOverlayState state) {
    _state = state;
  }
}

class _MessageContextMenuOverlay extends StatefulWidget {
  const _MessageContextMenuOverlay({
    required this.anchorRect,
    required this.message,
    required this.isOwn,
    required this.features,
    required this.brandMarks,
    required this.messagePreview,
    required this.onDismiss,
    required this.onReply,
    required this.onToggleReaction,
    required this.onForward,
    required this.onDelete,
    required this.onSendTip,
  });

  final Rect anchorRect;
  final Message message;
  final bool isOwn;
  final ChatFeatures features;
  final List<BrandReactionMark> brandMarks;
  final Widget messagePreview;
  final VoidCallback onDismiss;
  final VoidCallback onReply;
  final void Function(String value, ReactionKind kind) onToggleReaction;
  final VoidCallback onForward;
  final VoidCallback? onDelete;
  final void Function(int amountCents, String currency)? onSendTip;

  @override
  State<_MessageContextMenuOverlay> createState() =>
      MessageContextMenuOverlayState();
}

class MessageContextMenuOverlayState extends State<_MessageContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showTipPresets = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    MessageContextMenu.registerState(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _controller.forward();
  }

  void _close() {
    if (_controller.status != AnimationStatus.dismissed &&
        _controller.status != AnimationStatus.reverse) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismissAnimated() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Future<void> _copyText() async {
    final text = widget.message.body.trim();
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied')),
      );
    }
    await _dismissAnimated();
  }

  void _openEmojiPicker() {
    HapticFeedback.selectionClick();
    setState(() => _showEmojiPicker = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    const reactionsHeight = 52.0;
    const actionsHeight = 220.0;
    const gap = 10.0;

    var anchor = widget.anchorRect;
    final totalNeeded =
        reactionsHeight + gap + anchor.height + gap + actionsHeight;
    final availableTop = anchor.top - padding.top;
    final availableBottom = screen.height - anchor.bottom - padding.bottom;

    var verticalShift = 0.0;
    if (availableTop < reactionsHeight + gap && availableBottom > totalNeeded) {
      verticalShift = (reactionsHeight + gap - availableTop).clamp(0.0, 80.0);
    } else if (availableBottom < actionsHeight + gap &&
        availableTop > totalNeeded) {
      verticalShift = -(actionsHeight + gap - availableBottom).clamp(0.0, 80.0);
    }

    anchor = anchor.shift(Offset(0, verticalShift));

    final reactionsTop = anchor.top - reactionsHeight - gap;
    final actionsTop = anchor.bottom + gap;

    final showTip = widget.features.tipping &&
        !widget.isOwn &&
        widget.onSendTip != null &&
        !widget.message.isSystem;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissAnimated,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 8 * animation.value,
                      sigmaY: 8 * animation.value,
                    ),
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: 0.45 * animation.value,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: anchor.left,
            top: anchor.top,
            width: anchor.width,
            height: anchor.height,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.92 + 0.08 * animation.value,
                  alignment: widget.isOwn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Opacity(
                    opacity: animation.value,
                    child: child,
                  ),
                );
              },
              child: widget.messagePreview,
            ),
          ),
          if (widget.features.reactions && !_showTipPresets)
            Positioned(
              left: 0,
              right: 0,
              top: reactionsTop.clamp(padding.top, screen.height),
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  alignment: widget.isOwn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: _ReactionsBar(
                    theme: theme,
                    message: widget.message,
                    brandMarks: widget.brandMarks,
                    showEmojiPicker: _showEmojiPicker,
                    onToggleReaction: widget.onToggleReaction,
                    onOpenEmojiPicker: _openEmojiPicker,
                    onCloseEmojiPicker: () =>
                        setState(() => _showEmojiPicker = false),
                  ),
                ),
              ),
            ),
          Positioned(
            left: widget.isOwn ? null : 16,
            right: widget.isOwn ? 16 : null,
            top: actionsTop.clamp(padding.top, screen.height - actionsHeight),
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                alignment: widget.isOwn
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: _showTipPresets
                    ? _TipPresetsMenu(
                        theme: theme,
                        onSelect: (amount) {
                          widget.onSendTip?.call(amount, TipPresets.currency);
                          _dismissAnimated();
                        },
                        onBack: () => setState(() => _showTipPresets = false),
                      )
                    : _ActionsMenu(
                        theme: theme,
                        isOwn: widget.isOwn,
                        features: widget.features,
                        showTip: showTip,
                        canCopy: widget.message.body.trim().isNotEmpty,
                        onReply: () async {
                          await _dismissAnimated();
                          widget.onReply();
                        },
                        onCopy: _copyText,
                        onTip: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showTipPresets = true);
                        },
                        onForward: () async {
                          await _dismissAnimated();
                          widget.onForward();
                        },
                        onDelete: widget.onDelete == null
                            ? null
                            : () async {
                                await _dismissAnimated();
                                widget.onDelete!();
                              },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionsBar extends StatelessWidget {
  const _ReactionsBar({
    required this.theme,
    required this.message,
    required this.brandMarks,
    required this.showEmojiPicker,
    required this.onToggleReaction,
    required this.onOpenEmojiPicker,
    required this.onCloseEmojiPicker,
  });

  final ChatTheme theme;
  final Message message;
  final List<BrandReactionMark> brandMarks;
  final bool showEmojiPicker;
  final void Function(String value, ReactionKind kind) onToggleReaction;
  final VoidCallback onOpenEmojiPicker;
  final VoidCallback onCloseEmojiPicker;

  @override
  Widget build(BuildContext context) {
    if (showEmojiPicker) {
      return _EmojiPickerPanel(
        theme: theme,
        brandMarks: brandMarks,
        onSelect: (value, kind) {
          HapticFeedback.selectionClick();
          onToggleReaction(value, kind);
          onCloseEmojiPicker();
        },
        onClose: onCloseEmojiPicker,
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in kQuickReactions)
              _ReactionChip(
                label: emoji,
                isSelected: message.reactions.any(
                  (r) => r.value == emoji && r.kind == ReactionKind.emoji,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggleReaction(emoji, ReactionKind.emoji);
                },
              ),
            _ReactionChip(
              label: '+',
              isSelected: false,
              isPlus: true,
              accentColor: theme.accentColor,
              onTap: onOpenEmojiPicker,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isPlus = false,
    this.accentColor,
  });

  final String label;
  final bool isSelected;
  final bool isPlus;
  final Color? accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isSelected
            ? (accentColor ?? Colors.blue).withValues(alpha: 0.18)
            : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isPlus ? 22 : 24,
                  fontWeight: isPlus ? FontWeight.w700 : FontWeight.normal,
                  color: isPlus ? accentColor : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiPickerPanel extends StatelessWidget {
  const _EmojiPickerPanel({
    required this.theme,
    required this.brandMarks,
    required this.onSelect,
    required this.onClose,
  });

  final ChatTheme theme;
  final List<BrandReactionMark> brandMarks;
  final void Function(String value, ReactionKind kind) onSelect;
  final VoidCallback onClose;

  static const _extraEmojis = [
    '😍', '😮', '😢', '😡', '🎉', '🔥', '👏', '💯', '🙌', '✨',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'React',
                  style: TextStyle(
                    color: theme.inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: theme.subtleTextColor, size: 20),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final emoji in [...kQuickReactions, ..._extraEmojis])
                  _EmojiButton(
                    emoji: emoji,
                    onTap: () => onSelect(emoji, ReactionKind.emoji),
                  ),
                for (final mark in brandMarks)
                  _EmojiButton(
                    emoji: mark.emojiFallback,
                    onTap: () => onSelect(mark.id, ReactionKind.brand),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.theme,
    required this.isOwn,
    required this.features,
    required this.showTip,
    required this.canCopy,
    required this.onReply,
    required this.onCopy,
    required this.onTip,
    required this.onForward,
    required this.onDelete,
  });

  final ChatTheme theme;
  final bool isOwn;
  final ChatFeatures features;
  final bool showTip;
  final bool canCopy;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onTip;
  final VoidCallback onForward;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionItem>[
      if (features.replies)
        _ActionItem(
          icon: Icons.reply_rounded,
          label: 'Reply',
          onTap: onReply,
        ),
      if (canCopy)
        _ActionItem(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onTap: onCopy,
        ),
      if (showTip)
        _ActionItem(
          icon: Icons.volunteer_activism_outlined,
          label: 'Tip',
          onTap: onTip,
        ),
      _ActionItem(
        icon: Icons.forward_rounded,
        label: 'Forward',
        onTap: onForward,
      ),
      if (isOwn && onDelete != null)
        _ActionItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          isDestructive: true,
          onTap: onDelete!,
        ),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.surfaceColor.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            _ActionRow(item: actions[i], theme: theme),
          ],
        ],
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.item, required this.theme});

  final _ActionItem item;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive ? Colors.red.shade400 : theme.inkColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipPresetsMenu extends StatelessWidget {
  const _TipPresetsMenu({
    required this.theme,
    required this.onSelect,
    required this.onBack,
  });

  final ChatTheme theme;
  final void Function(int amountCents) onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.surfaceColor.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.chevron_left, color: theme.subtleTextColor),
                    Text(
                      'Tip amount',
                      style: TextStyle(
                        color: theme.inkColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          for (var i = 0; i < TipPresets.amountCents.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            TipPresetAmountRow(
              amountCents: TipPresets.amountCents[i],
              onTap: () => onSelect(TipPresets.amountCents[i]),
            ),
          ],
        ],
      ),
    );
  }
}
