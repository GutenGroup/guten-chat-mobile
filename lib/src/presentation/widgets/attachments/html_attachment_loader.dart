import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/models/message_attachment.dart';
import '../../theme/chat_theme.dart';
import '../../utils/attachment_utils.dart';
import 'html_document_card.dart';

class HtmlAttachmentLoader extends StatelessWidget {
  const HtmlAttachmentLoader({
    super.key,
    required this.attachment,
    required this.resolveBytes,
  });

  final MessageAttachment attachment;
  final Future<List<int>> Function(String storagePath) resolveBytes;

  Future<List<int>> _loadBytes() async {
    if (isLocalAttachmentPath(attachment.storagePath)) {
      return File(attachment.storagePath).readAsBytes();
    }
    return resolveBytes(attachment.storagePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return FutureBuilder<List<int>>(
      future: _loadBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.accentColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: 80,
            alignment: Alignment.center,
            child: Text(
              'HTML preview unavailable',
              style: TextStyle(color: theme.subtleTextColor),
            ),
          );
        }

        return HtmlDocumentCard(
          title: attachment.displayName,
          html: String.fromCharCodes(snapshot.data!),
        );
      },
    );
  }
}
