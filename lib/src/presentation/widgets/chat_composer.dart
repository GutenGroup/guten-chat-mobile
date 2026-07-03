import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_attachment.dart';
import '../../domain/models/reaction.dart';
import '../models/attachment_send_request.dart';
import '../theme/chat_theme.dart';
import '../utils/attachment_utils.dart';
import 'expandable_icon_menu.dart';
import 'voice_recorder_sheet.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onTypingChanged,
    required this.onAttachment,
    required this.features,
    required this.replyToMessage,
    required this.onClearReply,
    this.brandMarks = const [],
    this.onToggleReaction,
    this.onRequestPayment,
    this.onSendTip,
  });

  final ValueChanged<String> onSend;
  final ValueChanged<bool> onTypingChanged;
  final ValueChanged<AttachmentSendRequest> onAttachment;
  final ChatFeatures features;
  final Message? replyToMessage;
  final VoidCallback onClearReply;
  final List<BrandReactionMark> brandMarks;
  final void Function(String value, ReactionKind kind)? onToggleReaction;
  final VoidCallback? onRequestPayment;
  final VoidCallback? onSendTip;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
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

  Future<void> _recordVoiceNote() async {
    final result = await VoiceRecorderSheet.show(context);
    if (result == null) {
      return;
    }
    widget.onAttachment(
      AttachmentSendRequest(
        localPath: result.path,
        kind: AttachmentKind.voiceNote,
        fileName: 'voice_note.m4a',
        durationMs: result.durationMs,
      ),
    );
  }

  Future<void> _pickCamera() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) {
        return;
      }
      await _emitImageAttachment(photo);
    } on PlatformException catch (error) {
      _showPermissionMessage(error.message ?? 'Camera permission denied');
    } catch (error) {
      _showPermissionMessage(error.toString());
    }
  }

  Future<void> _pickGallery() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (photo == null) {
        return;
      }
      await _emitImageAttachment(photo);
    } on PlatformException catch (error) {
      _showPermissionMessage(error.message ?? 'Photo library permission denied');
    } catch (error) {
      _showPermissionMessage(error.toString());
    }
  }

  Future<void> _pickHtmlFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['html', 'htm'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      final path = file.path;
      if (path == null) {
        return;
      }
      widget.onAttachment(
        AttachmentSendRequest(
          localPath: path,
          kind: AttachmentKind.file,
          fileName: file.name,
          fileSizeBytes: file.size,
        ),
      );
    } on PlatformException catch (error) {
      _showPermissionMessage(error.message ?? 'Could not pick HTML file');
    } catch (error) {
      _showPermissionMessage(error.toString());
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: false);
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      final path = file.path;
      if (path == null) {
        return;
      }
      widget.onAttachment(
        AttachmentSendRequest(
          localPath: path,
          kind: AttachmentKind.file,
          caption: _controller.text.trim().isEmpty ? null : _controller.text,
          fileName: file.name,
          fileSizeBytes: file.size,
        ),
      );
      _controller.clear();
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged(false);
      }
    } on PlatformException catch (error) {
      _showPermissionMessage(error.message ?? 'Could not pick file');
    } catch (error) {
      _showPermissionMessage(error.toString());
    }
  }

  Future<void> _emitImageAttachment(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final dimensions = await readImageDimensions(bytes);
    widget.onAttachment(
      AttachmentSendRequest(
        localPath: photo.path,
        kind: AttachmentKind.image,
        caption: _controller.text.trim().isEmpty ? null : _controller.text,
        fileName: photo.name,
        fileSizeBytes: bytes.length,
        widthPx: dimensions?.$1,
        heightPx: dimensions?.$2,
      ),
    );
    _controller.clear();
    if (_isTyping) {
      _isTyping = false;
      widget.onTypingChanged(false);
    }
  }

  void _showPermissionMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<ExpandableMenuChoice> _buildMenuChoices() {
    final choices = <ExpandableMenuChoice>[
      ExpandableMenuChoice(
        icon: Icons.mic_rounded,
        label: 'Voice note',
        onTap: _recordVoiceNote,
      ),
      ExpandableMenuChoice(
        icon: Icons.image_rounded,
        label: 'Photo',
        onTap: _pickGallery,
      ),
      ExpandableMenuChoice(
        icon: Icons.photo_camera_rounded,
        label: 'Camera',
        onTap: _pickCamera,
      ),
      ExpandableMenuChoice(
        icon: Icons.html_rounded,
        label: 'HTML file',
        onTap: _pickHtmlFile,
      ),
      ExpandableMenuChoice(
        icon: Icons.attach_file_rounded,
        label: 'File',
        onTap: _pickFile,
      ),
    ];

    final hasPayment = widget.onRequestPayment != null;
    final hasTip = widget.onSendTip != null;
    if (hasPayment) {
      choices.add(
        ExpandableMenuChoice(
          icon: Icons.request_page_outlined,
          label: 'Request payment',
          dividerBefore: true,
          onTap: widget.onRequestPayment!,
        ),
      );
    }
    if (hasTip) {
      choices.add(
        ExpandableMenuChoice(
          icon: Icons.volunteer_activism_outlined,
          label: 'Send tip',
          dividerBefore: !hasPayment,
          onTap: widget.onSendTip!,
        ),
      );
    }

    return choices;
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    // Single owner of the keyboard inset (the thread Scaffold sets
    // resizeToAvoidBottomInset: false). Plain Padding, not AnimatedPadding:
    // iOS delivers viewInsets already animated on the exact keyboard curve,
    // so any extra tween lags the keyboard and un-glues the composer.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ExpandableIconMenu(
                      triggerIcon: Icons.add_rounded,
                      choices: _buildMenuChoices(),
                    ),
                    const SizedBox(width: 4),
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
