import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/chat_theme.dart';

/// Hand-rolled speed-dial menu — rotating trigger, staggered icon pills,
/// tap-outside scrim. Mirrors Techpool's ExpandableCaptureButton pattern.
class ExpandableIconMenu extends StatefulWidget {
  const ExpandableIconMenu({
    super.key,
    required this.choices,
    this.triggerIcon = Icons.add_rounded,
    this.triggerSize = 44,
    this.pillSize = 44,
    this.pitch = 52,
    this.baseOffset = 56,
    this.alignment = ExpandableMenuAlignment.bottomLeft,
    this.enabled = true,
  });

  final List<ExpandableMenuChoice> choices;
  final IconData triggerIcon;
  final double triggerSize;
  final double pillSize;
  final double pitch;
  final double baseOffset;
  final ExpandableMenuAlignment alignment;
  final bool enabled;

  @override
  State<ExpandableIconMenu> createState() => _ExpandableIconMenuState();
}

enum ExpandableMenuAlignment {
  bottomLeft,
  bottomRight,
}

class ExpandableMenuChoice {
  const ExpandableMenuChoice({
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
}

class _ExpandableIconMenuState extends State<ExpandableIconMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final _triggerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.enabled) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _showOverlay();
        _controller.forward();
      } else {
        _controller.reverse().whenComplete(_removeOverlay);
      }
    });
  }

  void _close() {
    if (!_isOpen) {
      return;
    }
    setState(() => _isOpen = false);
    _controller.reverse().whenComplete(_removeOverlay);
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    final triggerOffset = renderBox.localToGlobal(Offset.zero);
    final triggerSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ExpandableMenuOverlay(
        controller: _controller,
        choices: widget.choices,
        triggerOffset: triggerOffset,
        triggerSize: triggerSize,
        pillSize: widget.pillSize,
        pitch: widget.pitch,
        baseOffset: widget.baseOffset,
        alignment: widget.alignment,
        onClose: _close,
        onChoiceTap: (choice) {
          _close();
          choice.onTap();
        },
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return SizedBox(
      key: _triggerKey,
      width: widget.triggerSize,
      height: widget.triggerSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * (pi / 4),
            child: child,
          );
        },
        child: Material(
          color: theme.dividerColor.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _toggle,
            customBorder: const CircleBorder(),
            child: Icon(
              widget.triggerIcon,
              color: theme.inkColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableMenuOverlay extends StatelessWidget {
  const _ExpandableMenuOverlay({
    required this.controller,
    required this.choices,
    required this.triggerOffset,
    required this.triggerSize,
    required this.pillSize,
    required this.pitch,
    required this.baseOffset,
    required this.alignment,
    required this.onClose,
    required this.onChoiceTap,
  });

  final AnimationController controller;
  final List<ExpandableMenuChoice> choices;
  final Offset triggerOffset;
  final Size triggerSize;
  final double pillSize;
  final double pitch;
  final double baseOffset;
  final ExpandableMenuAlignment alignment;
  final VoidCallback onClose;
  final void Function(ExpandableMenuChoice choice) onChoiceTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final isLeft = alignment == ExpandableMenuAlignment.bottomLeft;
    final horizontal = isLeft
        ? triggerOffset.dx
        : triggerOffset.dx + triggerSize.width - pillSize;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        for (var i = 0; i < choices.length; i++)
          _MenuPill(
            controller: controller,
            index: i,
            bottom: MediaQuery.sizeOf(context).height -
                triggerOffset.dy -
                triggerSize.height +
                baseOffset +
                12 +
                i * pitch,
            left: horizontal,
            size: pillSize,
            icon: choices[i].icon,
            label: choices[i].label,
            theme: theme,
            onTap: () => onChoiceTap(choices[i]),
          ),
      ],
    );
  }
}

class _MenuPill extends StatelessWidget {
  const _MenuPill({
    required this.controller,
    required this.index,
    required this.bottom,
    required this.left,
    required this.size,
    required this.icon,
    required this.theme,
    required this.onTap,
    this.label,
  });

  final AnimationController controller;
  final int index;
  final double bottom;
  final double left;
  final double size;
  final IconData icon;
  final ChatTheme theme;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final start = index * 0.15;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final hasLabel = label != null && label!.isNotEmpty;

    return Positioned(
      left: left,
      bottom: bottom,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(animation),
          child: Material(
            color: theme.surfaceColor,
            elevation: 4,
            shape: hasLabel
                ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))
                : const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: hasLabel
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    )
                  : const CircleBorder(),
              splashColor: theme.accentColor.withValues(alpha: 0.2),
              highlightColor: theme.accentColor.withValues(alpha: 0.12),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hasLabel ? 12 : 0,
                  vertical: hasLabel ? 8 : 0,
                ),
                child: SizedBox(
                  width: hasLabel ? null : size,
                  height: hasLabel ? null : size,
                  child: hasLabel
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: theme.accentColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              label!,
                              style: TextStyle(
                                color: theme.inkColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Icon(icon, color: theme.inkColor, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
