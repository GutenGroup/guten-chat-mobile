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

/// Host-injected theme config. Base palette is always black & white; only
/// [accentColor] carries brand colour (Fysigo teal, Techpool crimson, etc.).
class GutenChatTheme {
  const GutenChatTheme({
    this.accentColor = const Color(0xFF888888),
    this.appearance = GutenChatAppearance.system,
  });

  /// Single accent token from the host app's design system.
  final Color accentColor;

  /// System / light / dark override for the chat shell.
  final GutenChatAppearance appearance;

  GutenChatTheme copyWith({
    Color? accentColor,
    GutenChatAppearance? appearance,
  }) {
    return GutenChatTheme(
      accentColor: accentColor ?? this.accentColor,
      appearance: appearance ?? this.appearance,
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
      return ChatTheme(
        accentColor: accentColor,
        paidAccentColor: paidAccentColor,
        brightness: Brightness.dark,
        backgroundColor: const Color(0xFF000000),
        surfaceColor: const Color(0xFF141618),
        sentBubbleColor: const Color(0xFFF3F3F3),
        receivedBubbleColor: const Color(0xFF141618),
        sentTextColor: const Color(0xFF000000),
        receivedTextColor: const Color(0xFFF3F3F3),
        composerBackgroundColor: const Color(0xFF000000),
        dividerColor: const Color(0xFF2A2A2A),
        subtleTextColor: const Color(0xFF9CA3AF),
        pillColor: const Color(0xFF141618),
        pillTextColor: const Color(0xFFF3F3F3),
        searchFieldColor: const Color(0xFF141618),
        bottomBarColor: const Color(0xCC000000),
        borderRadius: 18,
      );
    }

    return ChatTheme(
      accentColor: accentColor,
      paidAccentColor: paidAccentColor,
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceColor: const Color(0xFFF5F5F5),
      sentBubbleColor: const Color(0xFF000000),
      receivedBubbleColor: const Color(0xFFE8E8E8),
      sentTextColor: const Color(0xFFFFFFFF),
      receivedTextColor: const Color(0xFF000000),
      composerBackgroundColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE5E5E5),
      subtleTextColor: const Color(0xFF6B7280),
      pillColor: const Color(0xFF000000),
      pillTextColor: const Color(0xFFFFFFFF),
      searchFieldColor: const Color(0xFFF0F0F0),
      bottomBarColor: const Color(0xCCFFFFFF),
      borderRadius: 18,
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
    );
  }
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
      ),
    ),
    dividerColor: chatTheme.dividerColor,
    extensions: [chatTheme],
  );
}
