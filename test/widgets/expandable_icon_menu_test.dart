import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/presentation/theme/chat_theme.dart';
import 'package:guten_chat/src/presentation/widgets/expandable_icon_menu.dart';

void main() {
  testWidgets('ExpandableIconMenu shows trigger button', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGutenChatMaterialTheme(
          chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
        ),
        home: Scaffold(
          body: Center(
            child: ExpandableIconMenu(
              choices: [
                ExpandableMenuChoice(
                  icon: Icons.photo_camera_rounded,
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    expect(tapped, isTrue);
  });
}
