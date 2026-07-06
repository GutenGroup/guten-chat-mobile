import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';
import 'package:guten_chat/src/presentation/widgets/profile/profile_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: buildGutenChatMaterialTheme(
        chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
      ),
      home: Scaffold(body: child),
    );
  }

  testWidgets('appearance tile hidden when the host pins the appearance',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const ProfileScreen(
          displayName: 'Daniel',
          handle: 'daniel',
          avatarInitials: 'D',
          appearance: GutenChatAppearance.dark,
          onAppearanceChanged: null,
        ),
      ),
    );
    expect(find.text('Appearance'), findsNothing);
  });

  testWidgets('appearance tile shown when the host follows the system',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ProfileScreen(
          displayName: 'Daniel',
          handle: 'daniel',
          avatarInitials: 'D',
          appearance: GutenChatAppearance.system,
          onAppearanceChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Appearance'), findsOneWidget);
  });
}
