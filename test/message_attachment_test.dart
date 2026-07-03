import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/message_attachment.dart';

void main() {
  group('MessageAttachment', () {
    test('detects HTML files by extension', () {
      const attachment = MessageAttachment(
        id: '1',
        messageId: 'm1',
        kind: AttachmentKind.file,
        storagePath: 'conv/uuid/report.html',
        originalFileName: 'report.html',
      );

      expect(attachment.isHtml, isTrue);
      expect(attachment.displayName, 'report.html');
    });

    test('detects PDF files by extension', () {
      const attachment = MessageAttachment(
        id: '2',
        messageId: 'm1',
        kind: AttachmentKind.file,
        storagePath: 'conv/uuid/report.pdf',
        originalFileName: 'report.pdf',
      );

      expect(attachment.isPdf, isTrue);
      expect(attachment.isHtml, isFalse);
    });

    test('fromJson parses snake_case fields', () {
      final attachment = MessageAttachment.fromJson(const {
        'id': 'a1',
        'message_id': 'm1',
        'kind': 'image',
        'storage_path': 'conv/uuid.jpg',
        'width_px': 800,
        'height_px': 600,
      });

      expect(attachment.kind, AttachmentKind.image);
      expect(attachment.widthPx, 800);
      expect(attachment.heightPx, 600);
    });
  });
}
