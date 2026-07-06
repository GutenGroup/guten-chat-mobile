import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';

/// Shared translucent-glass chrome for app bars — the top-side twin of
/// [LiquidGlassBottomBar]'s treatment: content scrolls visibly under the
/// bar through a blur + the translucent bar tint.
///
/// Use as an [AppBar.flexibleSpace] / [SliverAppBar.flexibleSpace] with the
/// bar's own `backgroundColor` set to [Colors.transparent].
Widget glassBarFlexibleSpace(ChatTheme theme) {
  return ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: ColoredBox(
        color: theme.bottomBarColor,
        child: const SizedBox.expand(),
      ),
    ),
  );
}
