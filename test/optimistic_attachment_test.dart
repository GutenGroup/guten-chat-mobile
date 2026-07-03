import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/message_attachment.dart';
import 'package:guten_chat/src/presentation/utils/message_list_builder.dart';

void main() {
  test('createOptimisticMessage supports attachments', () {
    const attachment = MessageAttachment(
      id: 'att-1',
      messageId: 'temp-1',
      kind: AttachmentKind.image,
      storagePath: 'local/path.jpg',
    );

    final message = createOptimisticMessage(
      tempId: 'temp-1',
      conversationId: 'c1',
      senderProfileId: 'p1',
      body: 'Caption',
      attachments: [attachment],
      uploadProgress: 0.25,
    );

    expect(message.hasAttachments, isTrue);
    expect(message.uploadProgress, 0.25);
    expect(message.attachments.single.kind, AttachmentKind.image);
  });
}
