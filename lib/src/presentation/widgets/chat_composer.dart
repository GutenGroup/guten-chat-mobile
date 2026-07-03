import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/models/message.dart';
import '../../domain/models/reaction.dart';
import '../theme/chat_theme.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onTypingChanged,
    required this.features,
    required this.replyToMessage,
    required this.onClearReply,
    this.brandMarks = const [],
    this.onToggleReaction,
  });

  final ValueChanged<String> onSend;
  final ValueChanged<bool> onTypingChanged;
  final ChatFeatures features;
  final Message? replyToMessage;
  final VoidCallback onClearReply;
  final List<BrandReactionMark> brandMarks;
  final void Function(String value, ReactionKind kind)? onToggleReaction;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final typing = value.trim().isNotEmpty;
    if (typing != _isTyping) {
      _isTyping = typing;
      widget.onTypingChanged(typing);
    }
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    HapticFeedback.lightImpact();
    widget.onSend(text);
    _controller.clear();
    if (_isTyping) {
      _isTyping = false;
      widget.onTypingChanged(false);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Material(
          color: theme.composerBackgroundColor,
          elevation: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.replyToMessage != null && widget.features.replies)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to: ${widget.replyToMessage!.body}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.subtleTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: widget.onClearReply,
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Focus(
                        onKeyEvent: _handleKey,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 6,
                          textInputAction: TextInputAction.newline,
                          onChanged: _handleChanged,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            filled: true,
                            fillColor: theme.dividerColor.withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.inkColor,
                        foregroundColor: theme.backgroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
