import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/models/message_attachment.dart';
import '../../theme/chat_theme.dart';
import 'pdf_document_card.dart';

class PdfAttachmentLoader extends StatelessWidget {
  const PdfAttachmentLoader({
    super.key,
    required this.attachment,
    required this.resolveBytes,
  });

  final MessageAttachment attachment;
  final Future<List<int>> Function(String storagePath) resolveBytes;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return FutureBuilder<List<int>>(
      future: resolveBytes(attachment.storagePath),
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
              'PDF preview unavailable',
              style: TextStyle(color: theme.subtleTextColor),
            ),
          );
        }

        return PdfDocumentCard(
          title: attachment.displayName,
          bytes: Uint8List.fromList(snapshot.data!),
        );
      },
    );
  }
}
