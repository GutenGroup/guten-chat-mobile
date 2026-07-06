import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/chat_theme.dart';
import 'fullscreen_html_viewer.dart';

class HtmlDocumentCard extends StatefulWidget {
  const HtmlDocumentCard({
    super.key,
    required this.title,
    required this.html,
  });

  final String title;
  final String html;

  @override
  State<HtmlDocumentCard> createState() => _HtmlDocumentCardState();
}

class _HtmlDocumentCardState extends State<HtmlDocumentCard> {
  late final WebViewController _controller;
  var _isLoading = true;

  /// v0.5.0 thumbnail reset (web parity): shared HTML often ships zero body
  /// margin and would sit edge-to-edge in the preview — inject breathing room
  /// and a white ground. The fullscreen viewer renders the document raw.
  static const _thumbReset =
      '<style>html{background:#fff}body{margin:0;padding:14px;'
      'box-sizing:border-box}</style>';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }),
      )
      ..loadHtmlString(_thumbReset + widget.html);
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Material(
      color: theme.surfaceColor,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => FullscreenHtmlViewer.show(
          context,
          html: widget.html,
          title: widget.title,
        ),
        child: Container(
          // v0.5.0: document cards are content chrome, not brand surfaces —
          // min(280, available) cap, neutral line border on the raised surface.
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    Icon(Icons.language_rounded,
                        color: theme.subtleTextColor, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.subtleTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_full_rounded,
                        color: theme.subtleTextColor, size: 14),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
              SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: theme.accentColor,
                          strokeWidth: 2,
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
