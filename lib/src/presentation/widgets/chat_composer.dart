import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/models/chat_features.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_attachment.dart';
import '../../domain/models/reaction.dart';
import '../models/attachment_send_request.dart';
import '../theme/chat_theme.dart';
import '../utils/attachment_utils.dart';
import 'expandable_icon_menu.dart';
import 'voice_note_attachment_view.dart' show VoiceWaveform;

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

  // v0.5.0 inline recording state (web parity: recording swaps the input
  // row for a recording bar — no modal).
  final _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isStopping = false;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;
  String? _recordFilePath;

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.closeRecorder();
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

  Future<void> _startRecording() async {
    if (_isRecording) {
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showPermissionMessage(
        'Microphone access was denied — enable it in Settings to record '
        'voice notes.',
      );
      return;
    }

    try {
      await _recorder.openRecorder();
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        sampleRate: 44100,
        bitRate: 128000,
        audioSource: AudioSource.microphone,
      );
      _recordFilePath = path;
      _recordElapsed = Duration.zero;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordElapsed += const Duration(seconds: 1));
        }
      });
      HapticFeedback.mediumImpact();
      setState(() => _isRecording = true);
    } catch (_) {
      _showPermissionMessage('Could not start recording');
      await _teardownRecording();
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    // Re-entrancy guard: a double-tap on Send (or Discard-then-Send) must
    // not emit the same file twice — the platform stop/close calls suspend
    // long enough for a second tap to land.
    if (_isStopping) {
      return;
    }
    _isStopping = true;
    _recordTimer?.cancel();
    _recordTimer = null;
    String? path;
    try {
      path = await _recorder.stopRecorder();
    } catch (_) {
      path = _recordFilePath;
    }
    final resolvedPath = path ?? _recordFilePath;
    final elapsed = _recordElapsed;
    await _teardownRecording();

    if (send && resolvedPath != null && elapsed.inMilliseconds > 500) {
      widget.onAttachment(
        AttachmentSendRequest(
          localPath: resolvedPath,
          kind: AttachmentKind.voiceNote,
          fileName: 'voice_note.m4a',
          durationMs: elapsed.inMilliseconds,
        ),
      );
      return;
    }

    if (resolvedPath != null) {
      final file = File(resolvedPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _teardownRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    try {
      await _recorder.closeRecorder();
    } catch (_) {
      // Already closed.
    }
    _recordFilePath = null;
    _isStopping = false;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordElapsed = Duration.zero;
      });
    }
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        onTap: _startRecording,
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
                child: _isRecording
                    // v0.5.0 recording bar: discard → red pulsing dot → timer
                    // → waveform → send. Replaces the whole input row inline.
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () =>
                                unawaited(_stopRecording(send: false)),
                            tooltip: 'Discard recording',
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.subtleTextColor,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: theme.dividerColor
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  const _PulsingRecordDot(),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatElapsed(_recordElapsed),
                                    style: TextStyle(
                                      color: theme.inkColor,
                                      fontSize: 14,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: VoiceWaveform(
                                      progress: 1,
                                      ink: theme.accentColor,
                                      height: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton.filled(
                            onPressed: () =>
                                unawaited(_stopRecording(send: true)),
                            icon: const Icon(Icons.send_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.accentColor,
                              foregroundColor: theme.sentTextColor,
                            ),
                          ),
                        ],
                      )
                    : Row(
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
                                  fillColor: theme.dividerColor
                                      .withValues(alpha: 0.35),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // v0.5.0: the send affordance carries the accent.
                          IconButton.filled(
                            onPressed: _send,
                            icon: const Icon(Icons.send_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.accentColor,
                              foregroundColor: theme.sentTextColor,
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

/// The v0.5.0 recording indicator: a red dot pulsing 1 → 0.25 opacity on a
/// 1.3s cycle (web `gc-rec-pulse`). Danger red stays fixed across themes.
class _PulsingRecordDot extends StatefulWidget {
  const _PulsingRecordDot();

  @override
  State<_PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<_PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    lowerBound: 0.25,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFF34526),
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 10, height: 10),
      ),
    );
  }
}
