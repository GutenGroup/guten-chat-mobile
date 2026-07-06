import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';

void main() {
  group('GutenChatTheme', () {
    test('dark mode: accent outgoing bubbles on neutral ground (v0.5.0 tokens)',
        () {
      const config = GutenChatTheme(accentColor: Color(0xFF04AA72));
      final theme = config.toChatTheme(Brightness.dark);

      expect(theme.backgroundColor, const Color(0xFF000000));
      // tokens.json dark: bubble-in = #1f1f22 / #f3f3f3.
      expect(theme.receivedBubbleColor, const Color(0xFF1F1F22));
      expect(theme.receivedTextColor, const Color(0xFFF3F3F3));
      // bubble-out = host accent with accent-contrast ink (default white).
      expect(theme.sentBubbleColor, const Color(0xFF04AA72));
      expect(theme.sentTextColor, const Color(0xFFFFFFFF));
      expect(theme.accentColor, const Color(0xFF04AA72));
    });

    test('light mode: white ground, accent outgoing, token neutrals incoming',
        () {
      const config = GutenChatTheme(accentColor: Color(0xFFF50F3C));
      final theme = config.toChatTheme(Brightness.light);

      expect(theme.backgroundColor, const Color(0xFFFFFFFF));
      expect(theme.inkColor, const Color(0xFF000000));
      // tokens.json light: bubble-out = accent / accent-contrast,
      // bubble-in = #eceef1 / #0f0f0f.
      expect(theme.sentBubbleColor, const Color(0xFFF50F3C));
      expect(theme.sentTextColor, const Color(0xFFFFFFFF));
      expect(theme.receivedBubbleColor, const Color(0xFFECEEF1));
      expect(theme.receivedTextColor, const Color(0xFF0F0F0F));
    });

    test('host can override the accent-contrast ink', () {
      const config = GutenChatTheme(
        accentColor: Color(0xFFB8FF00),
        accentContrastColor: Color(0xFF0F0F0F),
      );
      final theme = config.toChatTheme(Brightness.dark);
      expect(theme.sentBubbleColor, const Color(0xFFB8FF00));
      expect(theme.sentTextColor, const Color(0xFF0F0F0F));
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
