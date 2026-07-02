import 'package:flutter/material.dart';

class ChatTheme extends ThemeExtension<ChatTheme> {
  const ChatTheme({
    this.primaryColor = const Color(0xFF2563EB),
    this.sentBubbleColor = const Color(0xFF2563EB),
    this.receivedBubbleColor = const Color(0xFFF3F4F6),
    this.sentTextColor = Colors.white,
    this.receivedTextColor = const Color(0xFF111827),
    this.backgroundColor = Colors.white,
    this.composerBackgroundColor = Colors.white,
    this.dividerColor = const Color(0xFFE5E7EB),
    this.subtleTextColor = const Color(0xFF6B7280),
    this.pillColor = const Color(0xFF2563EB),
    this.pillTextColor = Colors.white,
    this.borderRadius = 18,
  });

  final Color primaryColor;
  final Color sentBubbleColor;
  final Color receivedBubbleColor;
  final Color sentTextColor;
  final Color receivedTextColor;
  final Color backgroundColor;
  final Color composerBackgroundColor;
  final Color dividerColor;
  final Color subtleTextColor;
  final Color pillColor;
  final Color pillTextColor;
  final double borderRadius;

  @override
  ChatTheme copyWith({
    Color? primaryColor,
    Color? sentBubbleColor,
    Color? receivedBubbleColor,
    Color? sentTextColor,
    Color? receivedTextColor,
    Color? backgroundColor,
    Color? composerBackgroundColor,
    Color? dividerColor,
    Color? subtleTextColor,
    Color? pillColor,
    Color? pillTextColor,
    double? borderRadius,
  }) {
    return ChatTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      sentBubbleColor: sentBubbleColor ?? this.sentBubbleColor,
      receivedBubbleColor:
          receivedBubbleColor ?? this.receivedBubbleColor,
      sentTextColor: sentTextColor ?? this.sentTextColor,
      receivedTextColor: receivedTextColor ?? this.receivedTextColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      composerBackgroundColor:
          composerBackgroundColor ?? this.composerBackgroundColor,
      dividerColor: dividerColor ?? this.dividerColor,
      subtleTextColor: subtleTextColor ?? this.subtleTextColor,
      pillColor: pillColor ?? this.pillColor,
      pillTextColor: pillTextColor ?? this.pillTextColor,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) {
      return this;
    }
    return ChatTheme(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      sentBubbleColor:
          Color.lerp(sentBubbleColor, other.sentBubbleColor, t)!,
      receivedBubbleColor:
          Color.lerp(receivedBubbleColor, other.receivedBubbleColor, t)!,
      sentTextColor: Color.lerp(sentTextColor, other.sentTextColor, t)!,
      receivedTextColor:
          Color.lerp(receivedTextColor, other.receivedTextColor, t)!,
      backgroundColor:
          Color.lerp(backgroundColor, other.backgroundColor, t)!,
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
      borderRadius: borderRadius + (other.borderRadius - borderRadius) * t,
    );
  }
}

ChatTheme chatThemeOf(BuildContext context) {
  return Theme.of(context).extension<ChatTheme>() ?? const ChatTheme();
}
