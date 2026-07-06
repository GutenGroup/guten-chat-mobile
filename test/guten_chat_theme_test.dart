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

    test('host DLS tokens override the built-in palette', () {
      const config = GutenChatTheme(
        accentColor: Color(0xFF04AA72),
        backgroundColor: Color(0xFF0A1014),
        surfaceColor: Color(0xFF16211C),
        sentBubbleColor: Color(0xFF067A54),
        receivedBubbleColor: Color(0xFF1C2A24),
        sentTextColor: Color(0xFFE8FFF6),
        receivedTextColor: Color(0xFFD2E8DE),
        fontFamily: 'Inter',
        borderRadius: 12,
      );
      final theme = config.toChatTheme(Brightness.dark);

      expect(theme.backgroundColor, const Color(0xFF0A1014));
      expect(theme.surfaceColor, const Color(0xFF16211C));
      expect(theme.sentBubbleColor, const Color(0xFF067A54));
      expect(theme.receivedBubbleColor, const Color(0xFF1C2A24));
      expect(theme.sentTextColor, const Color(0xFFE8FFF6));
      expect(theme.receivedTextColor, const Color(0xFFD2E8DE));
      expect(theme.fontFamily, 'Inter');
      expect(theme.borderRadius, 12);
      // Derived neighbours follow the host tokens.
      expect(theme.composerBackgroundColor, const Color(0xFF0A1014));
      expect(theme.bottomBarColor, const Color(0xCC0A1014));
      expect(theme.searchFieldColor, const Color(0xFF16211C));
      expect(theme.pillColor, const Color(0xFF16211C));
    });

    test('light mode host tokens override and derive the same way', () {
      const config = GutenChatTheme(
        accentColor: Color(0xFF04AA72),
        backgroundColor: Color(0xFFFDF9F2),
        surfaceColor: Color(0xFFF2EBDD),
      );
      final theme = config.toChatTheme(Brightness.light);

      expect(theme.backgroundColor, const Color(0xFFFDF9F2));
      expect(theme.surfaceColor, const Color(0xFFF2EBDD));
      expect(theme.composerBackgroundColor, const Color(0xFFFDF9F2));
      expect(theme.bottomBarColor, const Color(0xCCFDF9F2));
      expect(theme.searchFieldColor, const Color(0xFFF2EBDD));
      // The light pill is the inverse chip (black ground, white ink) by
      // design — it does not follow the surface override.
      expect(theme.pillColor, const Color(0xFF000000));
    });

    test('omitted host tokens keep the v0.5.0 defaults (existing callers)',
        () {
      const config = GutenChatTheme(accentColor: Color(0xFF04AA72));
      final dark = config.toChatTheme(Brightness.dark);
      expect(dark.backgroundColor, const Color(0xFF000000));
      expect(dark.surfaceColor, const Color(0xFF141618));
      expect(dark.composerBackgroundColor, const Color(0xFF000000));
      expect(dark.bottomBarColor, const Color(0xCC000000));
      expect(dark.searchFieldColor, const Color(0xFF141618));
      expect(dark.pillColor, const Color(0xFF141618));
      expect(dark.fontFamily, isNull);
      expect(dark.borderRadius, 18);

      final light = config.toChatTheme(Brightness.light);
      expect(light.backgroundColor, const Color(0xFFFFFFFF));
      expect(light.composerBackgroundColor, const Color(0xFFFFFFFF));
      expect(light.bottomBarColor, const Color(0xCCFFFFFF));
      expect(light.searchFieldColor, const Color(0xFFF0F0F0));
      expect(light.pillColor, const Color(0xFF000000));
    });

    test('ChatTheme copyWith and lerp carry fontFamily', () {
      const config = GutenChatTheme(
        accentColor: Color(0xFF04AA72),
        fontFamily: 'Inter',
      );
      final theme = config.toChatTheme(Brightness.dark);
      expect(theme.copyWith(fontFamily: 'Sora').fontFamily, 'Sora');
      expect(theme.copyWith().fontFamily, 'Inter');

      final other = theme.copyWith(fontFamily: 'Sora');
      expect(theme.lerp(other, 0.25).fontFamily, 'Inter');
      expect(theme.lerp(other, 0.75).fontFamily, 'Sora');
    });

    test('fontFamily flows into the material theme', () {
      const config = GutenChatTheme(
        accentColor: Color(0xFF04AA72),
        fontFamily: 'Inter',
      );
      final materialTheme = buildGutenChatMaterialTheme(
        chatTheme: config.toChatTheme(Brightness.dark),
      );
      expect(materialTheme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(
        materialTheme.appBarTheme.titleTextStyle?.fontFamily,
        'Inter',
      );
    });
  });

  group('unthemed default warning', () {
    test('isUnthemed is true only for the placeholder config', () {
      expect(const GutenChatTheme().isUnthemed, isTrue);
      expect(
        const GutenChatTheme(appearance: GutenChatAppearance.dark).isUnthemed,
        isTrue,
      );
      expect(
        const GutenChatTheme(accentColor: Color(0xFF04AA72)).isUnthemed,
        isFalse,
      );
      expect(
        const GutenChatTheme(fontFamily: 'Inter').isUnthemed,
        isFalse,
      );
      expect(
        const GutenChatTheme(accentContrastColor: Color(0xFF0F0F0F))
            .isUnthemed,
        isFalse,
      );
    });

    test('debugCheckGutenChatHostTheme prints the banner once', () {
      debugResetGutenChatThemeWarning();
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        logs.add(message ?? '');
      };
      try {
        debugCheckGutenChatHostTheme(const GutenChatTheme());
        debugCheckGutenChatHostTheme(const GutenChatTheme());
      } finally {
        debugPrint = original;
      }
      expect(logs, hasLength(1));
      expect(logs.single, contains('NO HOST THEME PROVIDED'));
      expect(logs.single, contains('GutenChatTheme('));
    });

    test('a themed host produces no warning', () {
      debugResetGutenChatThemeWarning();
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        logs.add(message ?? '');
      };
      try {
        debugCheckGutenChatHostTheme(
          const GutenChatTheme(accentColor: Color(0xFF04AA72)),
        );
      } finally {
        debugPrint = original;
      }
      expect(logs, isEmpty);
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
