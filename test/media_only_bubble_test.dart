import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';
import 'package:guten_chat/src/presentation/widgets/message_bubble.dart'
    show MessageBubbleContent;

void main() {
  MessageAttachment attachment(AttachmentKind kind) => MessageAttachment(
        id: 'a1',
        messageId: 'm1',
        kind: kind,
        storagePath: 'conv/a1.png',
      );

  Message message({
    String body = '',
    List<MessageAttachment> attachments = const [],
    String? replyPreview,
  }) =>
      Message(
        id: 'm1',
        conversationId: 'c1',
        senderProfileId: 'p1',
        body: body,
        createdAt: DateTime(2026, 7, 5, 12),
        replyPreview: replyPreview,
        attachments: attachments,
      );

  group('MessageBubbleContent.isMediaOnly (v0.5.0 media tile)', () {
    test('true for a lone image with no text', () {
      expect(
        MessageBubbleContent.isMediaOnly(
          message(attachments: [attachment(AttachmentKind.image)]),
        ),
        isTrue,
      );
    });

    test('false when the message carries text', () {
      expect(
        MessageBubbleContent.isMediaOnly(
          message(
            body: 'look at this',
            attachments: [attachment(AttachmentKind.image)],
          ),
        ),
        isFalse,
      );
    });

    test('false for non-image attachments', () {
      expect(
        MessageBubbleContent.isMediaOnly(
          message(attachments: [attachment(AttachmentKind.voiceNote)]),
        ),
        isFalse,
      );
    });

    test('false for a reply with an image (reply preview renders in-bubble)',
        () {
      expect(
        MessageBubbleContent.isMediaOnly(
          message(
            replyPreview: 'original',
            attachments: [attachment(AttachmentKind.image)],
          ),
        ),
        isFalse,
      );
    });
  });
}
