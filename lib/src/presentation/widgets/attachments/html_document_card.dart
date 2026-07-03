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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }),
      )
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Material(
      color: theme.backgroundColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => FullscreenHtmlViewer.show(
          context,
          html: widget.html,
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
                    Icon(Icons.language_rounded,
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
