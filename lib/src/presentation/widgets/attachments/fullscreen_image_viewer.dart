import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';

class FullscreenImageViewer {
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String title,
    bool isLocalFile = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullscreenImagePage(
          imageUrl: imageUrl,
          title: title,
          isLocalFile: isLocalFile,
        ),
      ),
    );
  }
}

class _FullscreenImagePage extends StatelessWidget {
  const _FullscreenImagePage({
    required this.imageUrl,
    required this.title,
    this.isLocalFile = false,
  });

  final String imageUrl;
  final String title;
  final bool isLocalFile;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: theme.inkColor,
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: isLocalFile
              ? Image.file(File(imageUrl), fit: BoxFit.contain)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }
                    return CircularProgressIndicator(color: theme.accentColor);
                  },
                ),
        ),
      ),
    );
  }
}
