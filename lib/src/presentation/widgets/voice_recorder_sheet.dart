import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../theme/chat_theme.dart';

/// In-app voice note recorder — returns local file path + duration on send.
class VoiceRecorderSheet extends StatefulWidget {
  const VoiceRecorderSheet({super.key});

  static Future<({String path, int durationMs})?> show(BuildContext context) {
    return showModalBottomSheet<({String path, int durationMs})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceRecorderSheet(),
    );
  }

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _filePath = path;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });

    HapticFeedback.mediumImpact();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording({required bool send}) async {
    _timer?.cancel();
    final path = await _recorder.stop();
    final resolvedPath = path ?? _filePath;

    if (!mounted) {
      return;
    }

    if (send && resolvedPath != null && _elapsed.inMilliseconds > 500) {
      Navigator.pop(
        context,
        (path: resolvedPath, durationMs: _elapsed.inMilliseconds),
      );
      return;
    }

    if (resolvedPath != null) {
      final file = File(resolvedPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : theme.subtleTextColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? 'Recording' : 'Stopped',
                  style: TextStyle(
                    color: theme.inkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                color: theme.inkColor,
                fontSize: 36,
                fontWeight: FontWeight.w300,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _stopRecording(send: false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.subtleTextColor),
                  ),
                ),
                Material(
                  color: theme.accentColor,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _isRecording ? () => _stopRecording(send: true) : null,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 64),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
