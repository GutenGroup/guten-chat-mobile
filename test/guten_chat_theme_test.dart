import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';

void main() {
  group('GutenChatTheme', () {
    test('dark mode uses true black ground and monochrome bubbles', () {
      const config = GutenChatTheme(accentColor: Color(0xFF04AA72));
      final theme = config.toChatTheme(Brightness.dark);

      expect(theme.backgroundColor, const Color(0xFF000000));
      expect(theme.receivedBubbleColor, const Color(0xFF141618));
      expect(theme.sentBubbleColor, const Color(0xFFF3F3F3));
      expect(theme.receivedTextColor, const Color(0xFFF3F3F3));
      expect(theme.sentTextColor, const Color(0xFF000000));
      expect(theme.accentColor, const Color(0xFF04AA72));
    });

    test('light mode inverts to white ground and black ink', () {
      const config = GutenChatTheme(accentColor: Color(0xFFF50F3C));
      final theme = config.toChatTheme(Brightness.light);

      expect(theme.backgroundColor, const Color(0xFFFFFFFF));
      expect(theme.inkColor, const Color(0xFF000000));
      expect(theme.sentBubbleColor, const Color(0xFF000000));
      expect(theme.sentTextColor, const Color(0xFFFFFFFF));
    });

    test('resolveBrightness respects appearance override', () {
      const config = GutenChatTheme(appearance: GutenChatAppearance.dark);
      expect(
        config.resolveBrightness(Brightness.light),
        Brightness.dark,
      );

      const lightConfig = GutenChatTheme(appearance: GutenChatAppearance.light);
      expect(
        lightConfig.resolveBrightness(Brightness.dark),
        Brightness.light,
      );
    });

    test('default accent is neutral grey', () {
      const config = GutenChatTheme();
      expect(config.accentColor, const Color(0xFF888888));
    });
  });

  group('GroupIconMark', () {
    test('provides at least 10 default marks', () {
      expect(GroupIconMark.defaults.length, greaterThanOrEqualTo(10));
    });

    test('parse returns mark id from string', () {
      expect(GroupIconMark.parse('hexagon'), GroupIconMarkId.hexagon);
      expect(GroupIconMark.parse('unknown'), isNull);
    });
  });
}
