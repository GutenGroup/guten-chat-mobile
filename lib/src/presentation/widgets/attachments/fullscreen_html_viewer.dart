import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/chat_theme.dart';

class FullscreenHtmlViewer {
  static Future<void> show(
    BuildContext context, {
    required String html,
    required String title,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullscreenHtmlPage(html: html, title: title),
      ),
    );
  }
}

class _FullscreenHtmlPage extends StatefulWidget {
  const _FullscreenHtmlPage({required this.html, required this.title});

  final String html;
  final String title;

  @override
  State<_FullscreenHtmlPage> createState() => _FullscreenHtmlPageState();
}

class _FullscreenHtmlPageState extends State<_FullscreenHtmlPage> {
  late final WebViewController _controller;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.backgroundColor,
        foregroundColor: theme.inkColor,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: theme.accentColor),
            ),
        ],
      ),
    );
  }
}
