import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/message.dart';
import 'package:guten_chat/src/domain/models/reaction.dart';
import 'package:guten_chat/src/presentation/utils/message_list_builder.dart';

void main() {
  group('mergeMessages', () {
    test('dedupes optimistic message when server echoes client temp id', () {
      final server = [
        Message(
          id: 'real-1',
          conversationId: 'c1',
          senderProfileId: 'p1',
          body: 'Hello',
          createdAt: DateTime.utc(2026, 1, 1),
          clientTempId: 'temp-1',
        ),
      ];
      final optimistic = [
        Message(
          id: 'temp-1',
          conversationId: 'c1',
          senderProfileId: 'p1',
          body: 'Hello',
          createdAt: DateTime.utc(2026, 1, 1),
          status: MessageStatus.sending,
          clientTempId: 'temp-1',
        ),
      ];

      final merged = mergeMessages(
        serverMessages: server,
        optimisticMessages: optimistic,
      );

      expect(merged, hasLength(1));
      expect(merged.single.id, 'real-1');
    });
  });

  group('buildMessageListItems', () {
    test('inserts day dividers and groups consecutive senders', () {
      final messages = [
        Message(
          id: '1',
          conversationId: 'c1',
          senderProfileId: 'a',
          body: 'Hi',
          createdAt: DateTime.utc(2026, 7, 2, 10),
        ),
        Message(
          id: '2',
          conversationId: 'c1',
          senderProfileId: 'a',
          body: 'Again',
          createdAt: DateTime.utc(2026, 7, 2, 10, 1),
        ),
        Message(
          id: '3',
          conversationId: 'c1',
          senderProfileId: 'b',
          body: 'Hey',
          createdAt: DateTime.utc(2026, 7, 3, 9),
        ),
      ];

      final items = buildMessageListItems(messages, isGroup: true);

      expect(items.whereType<DayDividerItem>(), hasLength(2));
      final messageItems = items.whereType<MessageItem>().toList();
      expect(messageItems[0].isGroupedWithPrevious, isFalse);
      expect(messageItems[1].isGroupedWithPrevious, isTrue);
      expect(messageItems[2].showAvatar, isTrue);
    });
  });

  group('summarizeReactions', () {
    test('aggregates emoji reactions', () {
      final reactions = [
        Reaction(
          messageId: 'm1',
          profileId: 'p1',
          value: '👍',
          kind: ReactionKind.emoji,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        Reaction(
          messageId: 'm1',
          profileId: 'p2',
          value: '👍',
          kind: ReactionKind.emoji,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ];

      final summary = summarizeReactions(reactions, 'p1');
      expect(summary, hasLength(1));
      expect(summary.first.count, 2);
      expect(summary.first.includesMe, isTrue);
    });
  });
}
