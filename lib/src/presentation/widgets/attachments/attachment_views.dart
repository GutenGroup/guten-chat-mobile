import 'package:flutter/material.dart';

import '../../../domain/models/message_attachment.dart';
import '../../theme/chat_theme.dart';
import 'fullscreen_html_viewer.dart';
import 'fullscreen_image_viewer.dart';

typedef AttachmentUrlResolver = Future<String> Function(String storagePath);

typedef AttachmentBytesResolver = Future<List<int>> Function(String storagePath);

class ImageAttachmentView extends StatelessWidget {
  const ImageAttachmentView({
    super.key,
    required this.attachment,
    required this.resolveUrl,
    this.maxHeight = 220,
  });

  final MessageAttachment attachment;
  final AttachmentUrlResolver resolveUrl;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return FutureBuilder<String>(
      future: resolveUrl(attachment.storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.accentColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _AttachmentError(theme: theme, label: 'Image unavailable');
        }

        return GestureDetector(
          onTap: () => FullscreenImageViewer.show(
            context,
            imageUrl: snapshot.data!,
            title: attachment.displayName,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Image.network(
                snapshot.data!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    _AttachmentError(theme: theme, label: 'Image unavailable'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FileAttachmentChip extends StatelessWidget {
  const FileAttachmentChip({
    super.key,
    required this.attachment,
    required this.onTap,
  });

  final MessageAttachment attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final ext = attachment.extension;

    return Material(
      color: theme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForExtension(ext), color: theme.inkColor, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.inkColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (attachment.fileSizeBytes != null)
                      Text(
                        formatFileSize(attachment.fileSizeBytes!),
                        style: TextStyle(
                          color: theme.subtleTextColor,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.download_rounded, color: theme.subtleTextColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForExtension(String ext) {
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'xls' || 'xlsx' => Icons.table_chart_rounded,
      'zip' || 'rar' => Icons.folder_zip_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }
}

class _AttachmentError extends StatelessWidget {
  const _AttachmentError({required this.theme, required this.label});

  final ChatTheme theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: theme.subtleTextColor)),
    );
  }
}

String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Future<void> openAttachment({
  required BuildContext context,
  required MessageAttachment attachment,
  required AttachmentBytesResolver resolveBytes,
  required AttachmentUrlResolver resolveUrl,
}) async {
  if (attachment.isHtml) {
    final html = await resolveBytes(attachment.storagePath);
    if (!context.mounted) {
      return;
    }
    await FullscreenHtmlViewer.show(
      context,
      html: String.fromCharCodes(html),
      title: attachment.displayName,
    );
    return;
  }

  final url = await resolveUrl(attachment.storagePath);
  if (!context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(attachment.displayName),
      content: SelectableText(url),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
