import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';

void main() {
  testWidgets('LiquidGlassBottomBar shows Chats with bubble icon', (tester) async {
    var selected = GutenChatTab.chats;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGutenChatMaterialTheme(
          chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
        ),
        home: Scaffold(
          bottomNavigationBar: LiquidGlassBottomBar(
            selected: selected,
            profileInitials: 'DE',
            onSelected: (tab) => selected = tab,
          ),
        ),
      ),
    );

    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('Communities'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget);

    await tester.tap(find.text('Updates'));
    await tester.pump();
    expect(selected, GutenChatTab.updates);
  });

  testWidgets('active tab carries the host accent (web .gc-tab parity)',
      (tester) async {
    const accent = Color(0xFF04AA72);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGutenChatMaterialTheme(
          chatTheme: const GutenChatTheme(accentColor: accent)
              .toChatTheme(Brightness.dark),
        ),
        home: Scaffold(
          bottomNavigationBar: LiquidGlassBottomBar(
            selected: GutenChatTab.chats,
            profileInitials: 'DE',
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final selectedIcon = tester.widget<Icon>(find.byIcon(Icons.chat_bubble));
    expect(selectedIcon.color, accent);
    final unselectedIcon =
        tester.widget<Icon>(find.byIcon(Icons.groups_outlined));
    expect(unselectedIcon.color, isNot(accent));
  });
}
