import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/message.dart';
import 'package:guten_chat/src/presentation/utils/message_list_builder.dart';

void main() {
  group('isDevBuildBanner', () {
    test('matches commit hash day separator pattern', () {
      final message = Message(
        id: '1',
        conversationId: 'c1',
        senderProfileId: 'system',
        body: '8bd64f3 · Jul 3, 2026',
        createdAt: DateTime.utc(2026, 7, 3),
        isSystem: true,
      );

      expect(isDevBuildBanner(message), isTrue);
    });

    test('does not match regular messages', () {
      final message = Message(
        id: '2',
        conversationId: 'c1',
        senderProfileId: 'p1',
        body: 'Hello there',
        createdAt: DateTime.utc(2026, 7, 3),
      );

      expect(isDevBuildBanner(message), isFalse);
    });
  });
}
