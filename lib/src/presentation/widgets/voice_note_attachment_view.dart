import 'dart:async';
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../domain/models/message_attachment.dart';
import '../theme/chat_theme.dart';
import '../utils/attachment_utils.dart';
import 'attachments/attachment_views.dart';

/// v0.5.0 voice player (web parity): play button + scrubbable bar waveform +
/// elapsed/total time in ONE row, all inking from the bubble it sits in — so
/// it stays legible on the accent (own) bubble and the neutral (other) bubble
/// alike. No surface box of its own: the bubble is the surface.
class VoiceNoteAttachmentView extends StatefulWidget {
  const VoiceNoteAttachmentView({
    super.key,
    required this.attachment,
    required this.resolveUrl,
    this.ink,
  });

  final MessageAttachment attachment;
  final AttachmentUrlResolver resolveUrl;

  /// The bubble's text ink; falls back to the theme ink when absent.
  final Color? ink;

  @override
  State<VoiceNoteAttachmentView> createState() =>
      _VoiceNoteAttachmentViewState();
}

class _VoiceNoteAttachmentViewState extends State<VoiceNoteAttachmentView> {
  final _player = FlutterSoundPlayer();
  StreamSubscription<PlaybackDisposition>? _progressSub;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _hasStarted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.openPlayer();
      await _player.setSubscriptionDuration(const Duration(milliseconds: 100));

      final attachmentDuration = widget.attachment.durationMs;
      if (attachmentDuration != null) {
        _duration = Duration(milliseconds: attachmentDuration);
      }

      _progressSub = _player.onProgress?.listen((event) {
        if (!mounted) {
          return;
        }
        setState(() {
          _position = event.position;
          if (event.duration.inMilliseconds > 0) {
            _duration = event.duration;
          }
          _isPlaying = _player.isPlaying;
        });
      });
    } catch (_) {
      // Playback will remain disabled.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _resolvePlaybackUri() async {
    final path = widget.attachment.storagePath;
    if (isLocalAttachmentPath(path)) {
      return path;
    }
    return widget.resolveUrl(path);
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pausePlayer();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
      return;
    }

    try {
      if (!_hasStarted) {
        final uri = await _resolvePlaybackUri();
        final duration = await _player.startPlayer(
          fromURI: uri,
          codec: Codec.aacMP4,
          whenFinished: () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _position = Duration.zero;
                _hasStarted = false;
              });
            }
          },
        );
        _hasStarted = true;
        if (duration != null && duration.inMilliseconds > 0) {
          _duration = duration;
        }
      } else {
        if (_position >= _duration && _duration > Duration.zero) {
          await _player.seekToPlayer(Duration.zero);
        }
        await _player.resumePlayer();
      }
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    } catch (_) {
      // Keep UI in paused state.
    }
  }

  /// Web-parity scrub: fraction 0–1 across the waveform → seek. Only
  /// meaningful once a playback session exists (flutter_sound needs an open
  /// session to seek); before that a tap simply does nothing.
  Future<void> _seekToFraction(double fraction) async {
    if (!_hasStarted || _duration <= Duration.zero) {
      return;
    }
    final clamped = fraction.clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * clamped).round(),
    );
    try {
      await _player.seekToPlayer(target);
      if (mounted) {
        setState(() => _position = target);
      }
    } catch (_) {
      // Ignore seek failures; progress stream re-syncs.
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final ink = widget.ink ?? theme.inkColor;
    final totalMs = max(_duration.inMilliseconds, 1);
    final progress = (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 272),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: ink.withValues(alpha: 0.16),
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
                          color: ink,
                        ),
                      )
                    : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: ink,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: VoiceWaveform(
              progress: progress,
              ink: ink,
              onSeek: _seekToFraction,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_isPlaying ? _position : _duration),
            style: TextStyle(
              color: ink.withValues(alpha: 0.62),
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The v0.5.0 bar waveform — the SAME 32 deterministic bar heights the web
/// module ships (Waveform.tsx BAR_HEIGHTS), inked from the bubble: played
/// bars at full ink, unplayed at 26%. Tap or drag to scrub when [onSeek] is
/// provided.
class VoiceWaveform extends StatelessWidget {
  const VoiceWaveform({
    super.key,
    required this.progress,
    required this.ink,
    this.onSeek,
    this.height = 26,
  });

  final double progress;
  final Color ink;
  final ValueChanged<double>? onSeek;
  final double height;

  /// Web Waveform.tsx BAR_HEIGHTS (px, max 26).
  static const barHeights = [
    5, 9, 14, 7, 18, 11, 22, 8, 16, 25, 12, 6, 19, 10, 23, 14, //
    8, 17, 26, 11, 7, 20, 13, 9, 15, 22, 6, 18, 10, 24, 12, 8,
  ];

  @override
  Widget build(BuildContext context) {
    final wave = SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < barHeights.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: FractionallySizedBox(
                heightFactor: barHeights[i] / 26,
                alignment: Alignment.center,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: (i / barHeights.length) < progress
                        ? ink
                        : ink.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onSeek == null) {
      return wave;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void seekAt(double dx) {
          if (width <= 0) {
            return;
          }
          onSeek!((dx / width).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => seekAt(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => seekAt(d.localPosition.dx),
          child: wave,
        );
      },
    );
  }
}
