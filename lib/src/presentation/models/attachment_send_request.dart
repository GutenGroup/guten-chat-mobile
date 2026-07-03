import '../../domain/models/message_attachment.dart';

/// Local file picked from camera, gallery, or file picker before upload.
class AttachmentSendRequest {
  const AttachmentSendRequest({
    required this.localPath,
    required this.kind,
    this.caption,
    this.fileName,
    this.fileSizeBytes,
    this.widthPx,
    this.heightPx,
  });

  final String localPath;
  final AttachmentKind kind;
  final String? caption;
  final String? fileName;
  final int? fileSizeBytes;
  final int? widthPx;
  final int? heightPx;
}
