import 'package:flutter/material.dart';

/// How Guten Chat resolves light vs dark appearance.
enum GutenChatAppearance {
  /// Follow the host platform [Brightness].
  system,

  /// Force light (white ground, black ink).
  light,

  /// Force dark (true black ground, white ink).
  dark,
}

/// Host-injected theme config. Neutral ground with the host DLS accent doing
/// real work: outgoing bubbles carry [accentColor] with [accentContrastColor]
/// ink, incoming bubbles sit on a neutral raised surface — the v0.5.0 design
/// (iMessage/WhatsApp standard), value-identical to the web module. Colour
/// values come from guten-chat `foundation/design/tokens.json` (the ONE design
/// source); when the Flutter generator lands this file becomes generated.
///
/// **Every host app must pass a theme built from its own design system** — at
/// minimum the [accentColor]. The optional tokens ([backgroundColor],
/// [surfaceColor], bubble colors, [fontFamily], [borderRadius]) override the
/// built-in neutrals when the host DLS diverges from them; anything left null
/// derives the shipped default, so existing callers are value-identical.
/// Reference integration: Fysigo passes
/// `GutenChatTheme(accentColor: Color(0xFF04AA72), appearance: GutenChatAppearance.dark)`
/// on mobile and the same accent to web `<GutenChat accent theme>`.
class GutenChatTheme {
  const GutenChatTheme({
    this.accentColor = _defaultAccent,
    this.accentContrastColor = const Color(0xFFFFFFFF),
    this.appearance = GutenChatAppearance.system,
    this.backgroundColor,
    this.surfaceColor,
    this.sentBubbleColor,
    this.receivedBubbleColor,
    this.sentTextColor,
    this.receivedTextColor,
    this.fontFamily,
    this.borderRadius,
  });

  /// The placeholder accent shipped when a host passes no theme. Rendering
  /// this gray means the host DLS was never wired up — see [isUnthemed].
  static const Color _defaultAccent = Color(0xFF888888);

  /// Single accent token from the host app's design system.
  final Color accentColor;

  /// Ink on top of [accentColor] (web: `--accent-contrast`, default white).
  final Color accentContrastColor;

  /// System / light / dark override for the chat shell.
  final GutenChatAppearance appearance;

  /// Canvas behind the whole chat shell (web: `--gc-base`). Null derives the
  /// mode default (true black dark / white light). Also grounds the composer
  /// and tints the translucent bottom bar.
  final Color? backgroundColor;

  /// Raised neutral surface — cards, pills, search field ground (web:
  /// `--gc-raised`). Null derives the mode default.
  final Color? surfaceColor;

  /// Outgoing bubble fill. Null derives [accentColor] (the v0.5.0 design —
  /// accent does the talking).
  final Color? sentBubbleColor;

  /// Incoming bubble fill (web: `--gc-bubble-in-bg`). Null derives the
  /// tokens.json neutral for the mode.
  final Color? receivedBubbleColor;

  /// Ink on [sentBubbleColor]. Null derives [accentContrastColor].
  final Color? sentTextColor;

  /// Ink on [receivedBubbleColor]. Null derives the tokens.json neutral.
  final Color? receivedTextColor;

  /// Host DLS font family applied to the whole chat [ThemeData]. Null keeps
  /// the platform default.
  final String? fontFamily;

  /// Bubble corner radius (web: `--gc-radius-bubble`). Null derives 18.
  final double? borderRadius;

  /// True when this config is indistinguishable from the built-in placeholder
  /// (gray accent, no host tokens) — the host never adopted its DLS.
  bool get isUnthemed =>
      accentColor == _defaultAccent &&
      accentContrastColor == const Color(0xFFFFFFFF) &&
      backgroundColor == null &&
      surfaceColor == null &&
      sentBubbleColor == null &&
      receivedBubbleColor == null &&
      sentTextColor == null &&
      receivedTextColor == null &&
      fontFamily == null &&
      borderRadius == null;

  GutenChatTheme copyWith({
    Color? accentColor,
    Color? accentContrastColor,
    GutenChatAppearance? appearance,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? sentBubbleColor,
    Color? receivedBubbleColor,
    Color? sentTextColor,
    Color? receivedTextColor,
    String? fontFamily,
    double? borderRadius,
  }) {
    return GutenChatTheme(
      accentColor: accentColor ?? this.accentColor,
      accentContrastColor: accentContrastColor ?? this.accentContrastColor,
      appearance: appearance ?? this.appearance,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      sentBubbleColor: sentBubbleColor ?? this.sentBubbleColor,
      receivedBubbleColor: receivedBubbleColor ?? this.receivedBubbleColor,
      sentTextColor: sentTextColor ?? this.sentTextColor,
      receivedTextColor: receivedTextColor ?? this.receivedTextColor,
      fontFamily: fontFamily ?? this.fontFamily,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  Brightness resolveBrightness(Brightness platformBrightness) {
    return switch (appearance) {
      GutenChatAppearance.system => platformBrightness,
      GutenChatAppearance.light => Brightness.light,
      GutenChatAppearance.dark => Brightness.dark,
    };
  }

  /// Lime accent for paid communities and owner badges (design standard).
  Color get paidAccentColor => const Color(0xFFB8FF00);

  ChatTheme toChatTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      final base = backgroundColor ?? const Color(0xFF000000);
      return ChatTheme(
        accentColor: accentColor,
        paidAccentColor: paidAccentColor,
        brightness: Brightness.dark,
        backgroundColor: base,
        surfaceColor: surfaceColor ?? const Color(0xFF141618),
        // tokens.json dark: bubble-out = accent / accent-contrast,
        // bubble-in = #1f1f22 / #f3f3f3 (v0.5.0 — accent does the talking).
        sentBubbleColor: sentBubbleColor ?? accentColor,
        receivedBubbleColor: receivedBubbleColor ?? const Color(0xFF1F1F22),
        sentTextColor: sentTextColor ?? accentContrastColor,
        receivedTextColor: receivedTextColor ?? const Color(0xFFF3F3F3),
        composerBackgroundColor: base,
        dividerColor: const Color(0xFF2A2A2A),
        subtleTextColor: const Color(0xFF9CA3AF),
        pillColor: surfaceColor ?? const Color(0xFF141618),
        pillTextColor: const Color(0xFFF3F3F3),
        searchFieldColor: surfaceColor ?? const Color(0xFF141618),
        bottomBarColor: base.withAlpha(0xCC),
        fontFamily: fontFamily,
        borderRadius: borderRadius ?? 18,
      );
    }

    final base = backgroundColor ?? const Color(0xFFFFFFFF);
    return ChatTheme(
      accentColor: accentColor,
      paidAccentColor: paidAccentColor,
      brightness: Brightness.light,
      backgroundColor: base,
      surfaceColor: surfaceColor ?? const Color(0xFFF5F5F5),
      // tokens.json light: bubble-out = accent / accent-contrast,
      // bubble-in = #eceef1 / #0f0f0f.
      sentBubbleColor: sentBubbleColor ?? accentColor,
      receivedBubbleColor: receivedBubbleColor ?? const Color(0xFFECEEF1),
      sentTextColor: sentTextColor ?? accentContrastColor,
      receivedTextColor: receivedTextColor ?? const Color(0xFF0F0F0F),
      composerBackgroundColor: base,
      dividerColor: const Color(0xFFE5E5E5),
      subtleTextColor: const Color(0xFF6B7280),
      pillColor: const Color(0xFF000000),
      pillTextColor: const Color(0xFFFFFFFF),
      searchFieldColor: surfaceColor ?? const Color(0xFFF0F0F0),
      bottomBarColor: base.withAlpha(0xCC),
      fontFamily: fontFamily,
      borderRadius: borderRadius ?? 18,
    );
  }
}

/// Resolved monochrome palette + accent, attached via [ThemeExtension].
class ChatTheme extends ThemeExtension<ChatTheme> {
  const ChatTheme({
    required this.accentColor,
    required this.paidAccentColor,
    required this.brightness,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.sentBubbleColor,
    required this.receivedBubbleColor,
    required this.sentTextColor,
    required this.receivedTextColor,
    required this.composerBackgroundColor,
    required this.dividerColor,
    required this.subtleTextColor,
    required this.pillColor,
    required this.pillTextColor,
    required this.searchFieldColor,
    required this.bottomBarColor,
    required this.borderRadius,
    this.fontFamily,
  });

  final Color accentColor;
  final Color paidAccentColor;
  final Brightness brightness;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color sentBubbleColor;
  final Color receivedBubbleColor;
  final Color sentTextColor;
  final Color receivedTextColor;
  final Color composerBackgroundColor;
  final Color dividerColor;
  final Color subtleTextColor;
  final Color pillColor;
  final Color pillTextColor;
  final Color searchFieldColor;
  final Color bottomBarColor;
  final double borderRadius;

  /// Host DLS font family; null = platform default.
  final String? fontFamily;

  /// Back-compat alias — accent is never used as bubble fill by default.
  Color get primaryColor => accentColor;

  bool get isDark => brightness == Brightness.dark;

  Color get inkColor => isDark ? const Color(0xFFF3F3F3) : const Color(0xFF000000);

  @override
  ChatTheme copyWith({
    Color? accentColor,
    Color? paidAccentColor,
    Brightness? brightness,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? sentBubbleColor,
    Color? receivedBubbleColor,
    Color? sentTextColor,
    Color? receivedTextColor,
    Color? composerBackgroundColor,
    Color? dividerColor,
    Color? subtleTextColor,
    Color? pillColor,
    Color? pillTextColor,
    Color? searchFieldColor,
    Color? bottomBarColor,
    double? borderRadius,
    String? fontFamily,
  }) {
    return ChatTheme(
      accentColor: accentColor ?? this.accentColor,
      paidAccentColor: paidAccentColor ?? this.paidAccentColor,
      brightness: brightness ?? this.brightness,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      sentBubbleColor: sentBubbleColor ?? this.sentBubbleColor,
      receivedBubbleColor: receivedBubbleColor ?? this.receivedBubbleColor,
      sentTextColor: sentTextColor ?? this.sentTextColor,
      receivedTextColor: receivedTextColor ?? this.receivedTextColor,
      composerBackgroundColor:
          composerBackgroundColor ?? this.composerBackgroundColor,
      dividerColor: dividerColor ?? this.dividerColor,
      subtleTextColor: subtleTextColor ?? this.subtleTextColor,
      pillColor: pillColor ?? this.pillColor,
      pillTextColor: pillTextColor ?? this.pillTextColor,
      searchFieldColor: searchFieldColor ?? this.searchFieldColor,
      bottomBarColor: bottomBarColor ?? this.bottomBarColor,
      borderRadius: borderRadius ?? this.borderRadius,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) {
      return this;
    }
    return ChatTheme(
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      paidAccentColor: Color.lerp(paidAccentColor, other.paidAccentColor, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      sentBubbleColor:
          Color.lerp(sentBubbleColor, other.sentBubbleColor, t)!,
      receivedBubbleColor:
          Color.lerp(receivedBubbleColor, other.receivedBubbleColor, t)!,
      sentTextColor: Color.lerp(sentTextColor, other.sentTextColor, t)!,
      receivedTextColor:
          Color.lerp(receivedTextColor, other.receivedTextColor, t)!,
      composerBackgroundColor: Color.lerp(
        composerBackgroundColor,
        other.composerBackgroundColor,
        t,
      )!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      subtleTextColor:
          Color.lerp(subtleTextColor, other.subtleTextColor, t)!,
      pillColor: Color.lerp(pillColor, other.pillColor, t)!,
      pillTextColor: Color.lerp(pillTextColor, other.pillTextColor, t)!,
      searchFieldColor:
          Color.lerp(searchFieldColor, other.searchFieldColor, t)!,
      bottomBarColor: Color.lerp(bottomBarColor, other.bottomBarColor, t)!,
      borderRadius: borderRadius + (other.borderRadius - borderRadius) * t,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
    );
  }
}

/// Once-per-process latch for [debugCheckGutenChatHostTheme].
bool _warnedUnthemed = false;

/// Test hook: re-arm the unthemed-default warning.
@visibleForTesting
void debugResetGutenChatThemeWarning() {
  _warnedUnthemed = false;
}

/// Debug-only guard called by the `GutenChat` entrypoints: prints a prominent
/// warning (once per process) when the host mounted the chat without a theme,
/// so the placeholder gray never ships silently. Compiles away in release.
void debugCheckGutenChatHostTheme(GutenChatTheme theme) {
  assert(() {
    if (theme.isUnthemed && !_warnedUnthemed) {
      _warnedUnthemed = true;
      debugPrint(
        '\n'
        '┌────────────────────────────────────────────────────────────────────┐\n'
        '│ GutenChat: NO HOST THEME PROVIDED                                  │\n'
        '│                                                                    │\n'
        '│ The chat is rendering the placeholder gray default — NOT your      │\n'
        '│ design system. Pass GutenChatTheme(...) from your host DLS:        │\n'
        '│                                                                    │\n'
        '│   GutenChat(                                                       │\n'
        '│     theme: GutenChatTheme(                                         │\n'
        '│       accentColor: <your DLS accent>,                              │\n'
        '│       appearance: GutenChatAppearance.dark,                        │\n'
        '│     ),                                                             │\n'
        '│     ...                                                            │\n'
        '│   )                                                                │\n'
        '│                                                                    │\n'
        '│ Reference: Fysigo passes accentColor: Color(0xFF04AA72), dark.     │\n'
        '│ See README.md → "Theming — bring your host DLS".                   │\n'
        '└────────────────────────────────────────────────────────────────────┘',
      );
    }
    return true;
  }());
}

ChatTheme chatThemeOf(BuildContext context) {
  return Theme.of(context).extension<ChatTheme>() ??
      const GutenChatTheme().toChatTheme(Brightness.dark);
}

ThemeData buildGutenChatMaterialTheme({
  required ChatTheme chatTheme,
}) {
  final isDark = chatTheme.isDark;
  return ThemeData(
    useMaterial3: true,
    brightness: chatTheme.brightness,
    fontFamily: chatTheme.fontFamily,
    scaffoldBackgroundColor: chatTheme.backgroundColor,
    colorScheme: ColorScheme(
      brightness: chatTheme.brightness,
      primary: chatTheme.accentColor,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: chatTheme.accentColor,
      onSecondary: isDark ? Colors.black : Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: chatTheme.surfaceColor,
      onSurface: chatTheme.inkColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: chatTheme.backgroundColor,
      foregroundColor: chatTheme.inkColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: chatTheme.inkColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: chatTheme.fontFamily,
      ),
    ),
    dividerColor: chatTheme.dividerColor,
    extensions: [chatTheme],
  );
}
