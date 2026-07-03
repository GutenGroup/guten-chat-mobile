import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../domain/models/message_attachment.dart';
import '../../theme/chat_theme.dart';
import '../../utils/attachment_utils.dart';
import 'attachment_views.dart';

class VoiceNoteAttachmentView extends StatefulWidget {
  const VoiceNoteAttachmentView({
    super.key,
    required this.attachment,
    required this.resolveUrl,
  });

  final MessageAttachment attachment;
  final AttachmentUrlResolver resolveUrl;

  @override
  State<VoiceNoteAttachmentView> createState() =>
      _VoiceNoteAttachmentViewState();
}

class _VoiceNoteAttachmentViewState extends State<VoiceNoteAttachmentView> {
  final _player = AudioPlayer();
  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final path = widget.attachment.storagePath;
      if (_isLocalPath(path)) {
        await _player.setFilePath(path);
      } else {
        final url = await widget.resolveUrl(path);
        await _player.setUrl(url);
      }

      final attachmentDuration = widget.attachment.durationMs;
      if (attachmentDuration != null) {
        _duration = Duration(milliseconds: attachmentDuration);
      } else {
        _duration = _player.duration ?? Duration.zero;
      }

      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
        }
      });
    } catch (_) {
      // Playback will remain disabled.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isLocalPath(String path) => isLocalAttachmentPath(path);

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final totalMs = max(_duration.inMilliseconds, 1);
    final progress = (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Material(
            color: theme.accentColor.withValues(alpha: 0.15),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isLoading ? null : _togglePlayback,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36,
                height: 36,
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.accentColor,
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: theme.accentColor,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Waveform(
                  progress: progress,
                  accentColor: theme.accentColor,
                  trackColor: theme.dividerColor,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_isPlaying ? _position : _duration),
                  style: TextStyle(
                    color: theme.subtleTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  final double progress;
  final Color accentColor;
  final Color trackColor;

  static const _bars = [0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.6, 0.95, 0.5, 0.75, 0.45, 0.85];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _bars.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: FractionallySizedBox(
                  heightFactor: _bars[i],
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: (i / _bars.length) <= progress
                          ? accentColor
                          : trackColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
