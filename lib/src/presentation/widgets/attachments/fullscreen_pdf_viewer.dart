import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../theme/chat_theme.dart';

class FullscreenPdfViewer {
  static Future<void> show(
    BuildContext context, {
    required Uint8List bytes,
    required String title,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullscreenPdfPage(bytes: bytes, title: title),
      ),
    );
  }
}

class _FullscreenPdfPage extends StatefulWidget {
  const _FullscreenPdfPage({required this.bytes, required this.title});

  final Uint8List bytes;
  final String title;

  @override
  State<_FullscreenPdfPage> createState() => _FullscreenPdfPageState();
}

class _FullscreenPdfPageState extends State<_FullscreenPdfPage> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.backgroundColor,
        foregroundColor: theme.inkColor,
      ),
      body: PdfViewPinch(
        controller: _controller,
        scrollDirection: Axis.vertical,
      ),
    );
  }
}
