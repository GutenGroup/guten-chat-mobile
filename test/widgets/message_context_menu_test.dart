import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/chat_features.dart';
import 'package:guten_chat/src/domain/models/message.dart';
import 'package:guten_chat/src/presentation/theme/chat_theme.dart';
import 'package:guten_chat/src/presentation/widgets/message_context_menu.dart';

void main() {
  testWidgets('MessageContextMenu shows reactions and actions', (tester) async {
    final message = Message(
      id: 'm1',
      conversationId: 'c1',
      senderProfileId: 'other',
      body: 'Hello world',
      createdAt: DateTime.utc(2026, 7, 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGutenChatMaterialTheme(
          chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
        ),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    MessageContextMenu.show(
                      context: context,
                      anchorRect: const Rect.fromLTWH(40, 300, 200, 60),
                      message: message,
                      isOwn: false,
                      features: const ChatFeatures(reactions: true, replies: true),
                      onDismiss: () {},
                      onReply: () {},
                      onToggleReaction: (_, __) {},
                      onForward: () {},
                      onDelete: null,
                      onSendTip: null,
                      messagePreview: const Text('Hello world'),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
    expect(find.text('❤️'), findsOneWidget);
  });
}
