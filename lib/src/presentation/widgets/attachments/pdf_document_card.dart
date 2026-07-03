import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../theme/chat_theme.dart';
import 'fullscreen_pdf_viewer.dart';

class PdfDocumentCard extends StatefulWidget {
  const PdfDocumentCard({
    super.key,
    required this.title,
    required this.bytes,
  });

  final String title;
  final Uint8List bytes;

  @override
  State<PdfDocumentCard> createState() => _PdfDocumentCardState();
}

class _PdfDocumentCardState extends State<PdfDocumentCard> {
  PdfController? _controller;
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final controller = PdfController(
        document: PdfDocument.openData(widget.bytes),
      );
      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Material(
      color: theme.backgroundColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => FullscreenPdfViewer.show(
          context,
          bytes: widget.bytes,
          title: widget.title,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.accentColor.withValues(alpha: 0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded,
                        color: theme.accentColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.inkColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_full_rounded,
                        color: theme.subtleTextColor, size: 16),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
              SizedBox(
                height: 160,
                child: _buildPreview(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ChatTheme theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.accentColor,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null || _controller == null) {
      return Center(
        child: Text(
          'PDF preview unavailable',
          style: TextStyle(color: theme.subtleTextColor),
        ),
      );
    }

    return IgnorePointer(
      child: ClipRect(
        child: PdfView(
          controller: _controller!,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }
}
