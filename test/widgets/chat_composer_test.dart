import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/chat_features.dart';
import 'package:guten_chat/src/presentation/theme/chat_theme.dart';
import 'package:guten_chat/src/presentation/widgets/chat_composer.dart';

void main() {
  testWidgets('ChatComposer shows money menu items when callbacks set',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGutenChatMaterialTheme(
          chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
        ),
        home: Scaffold(
          body: ChatComposer(
            features: const ChatFeatures(
              paymentRequests: true,
              tipping: true,
            ),
            replyToMessage: null,
            onClearReply: () {},
            onSend: (_) {},
            onTypingChanged: (_) {},
            onAttachment: (_) {},
            onRequestPayment: () {},
            onSendTip: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Request payment'), findsOneWidget);
    expect(find.text('Send tip'), findsOneWidget);
  });

  testWidgets('ChatComposer hides money menu items when callbacks null',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGutenChatMaterialTheme(
          chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
        ),
        home: Scaffold(
          body: ChatComposer(
            features: const ChatFeatures(
              paymentRequests: true,
              tipping: true,
            ),
            replyToMessage: null,
            onClearReply: () {},
            onSend: (_) {},
            onTypingChanged: (_) {},
            onAttachment: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Request payment'), findsNothing);
    expect(find.text('Send tip'), findsNothing);
  });
}
