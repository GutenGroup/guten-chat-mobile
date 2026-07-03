import 'package:flutter/material.dart';

/// Built-in geometric group avatar marks (10+ defaults).
enum GroupIconMarkId {
  monogram,
  circle,
  diamond,
  hexagon,
  triangle,
  cross,
  star,
  wave,
  grid,
  ring,
  chevron,
  bolt,
}

class GroupIconMark {
  const GroupIconMark._(this.id, this.label);

  final GroupIconMarkId id;
  final String label;

  static const defaults = <GroupIconMark>[
    GroupIconMark._(GroupIconMarkId.monogram, 'Monogram'),
    GroupIconMark._(GroupIconMarkId.circle, 'Circle'),
    GroupIconMark._(GroupIconMarkId.diamond, 'Diamond'),
    GroupIconMark._(GroupIconMarkId.hexagon, 'Hexagon'),
    GroupIconMark._(GroupIconMarkId.triangle, 'Triangle'),
    GroupIconMark._(GroupIconMarkId.cross, 'Cross'),
    GroupIconMark._(GroupIconMarkId.star, 'Star'),
    GroupIconMark._(GroupIconMarkId.wave, 'Wave'),
    GroupIconMark._(GroupIconMarkId.grid, 'Grid'),
    GroupIconMark._(GroupIconMarkId.ring, 'Ring'),
    GroupIconMark._(GroupIconMarkId.chevron, 'Chevron'),
    GroupIconMark._(GroupIconMarkId.bolt, 'Bolt'),
  ];

  static GroupIconMarkId? parse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final mark in defaults) {
      if (mark.id.name == value) {
        return mark.id;
      }
    }
    return null;
  }
}

/// Renders a group avatar: uploaded image, built-in mark, or monogram fallback.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    super.key,
    this.title,
    this.imageUrl,
    this.markId,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? title;
  final String? imageUrl;
  final GroupIconMarkId? markId;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFF141618);
    final fg = foregroundColor ?? Colors.white;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    final resolvedMark = markId ?? GroupIconMarkId.monogram;
    if (resolvedMark == GroupIconMarkId.monogram) {
      final initial =
          (title != null && title!.isNotEmpty) ? title![0].toUpperCase() : '?';
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(
          initial,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.75,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: CustomPaint(
        size: Size.square(radius * 1.1),
        painter: _GroupMarkPainter(markId: resolvedMark, color: fg),
      ),
    );
  }
}

class _GroupMarkPainter extends CustomPainter {
  _GroupMarkPainter({required this.markId, required this.color});

  final GroupIconMarkId markId;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.08
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.32;

    switch (markId) {
      case GroupIconMarkId.circle:
        canvas.drawCircle(center, r, paint);
      case GroupIconMarkId.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      case GroupIconMarkId.hexagon:
        canvas.drawPath(_regularPolygon(center, r, 6), paint);
      case GroupIconMarkId.triangle:
        canvas.drawPath(_regularPolygon(center, r, 3, rotation: -1.5708), paint);
      case GroupIconMarkId.cross:
        canvas.drawLine(
          Offset(center.dx - r, center.dy - r),
          Offset(center.dx + r, center.dy + r),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx + r, center.dy - r),
          Offset(center.dx - r, center.dy + r),
          paint,
        );
      case GroupIconMarkId.star:
        canvas.drawPath(_starPath(center, r), fill);
      case GroupIconMarkId.wave:
        final path = Path()..moveTo(center.dx - r, center.dy);
        path.quadraticBezierTo(
          center.dx - r / 2,
          center.dy - r,
          center.dx,
          center.dy,
        );
        path.quadraticBezierTo(
          center.dx + r / 2,
          center.dy + r,
          center.dx + r,
          center.dy,
        );
        canvas.drawPath(path, paint);
      case GroupIconMarkId.grid:
        final cell = r * 0.55;
        for (var row = -1; row <= 1; row++) {
          for (var col = -1; col <= 1; col++) {
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(
                  center.dx + col * cell * 1.2,
                  center.dy + row * cell * 1.2,
                ),
                width: cell,
                height: cell,
              ),
              paint,
            );
          }
        }
      case GroupIconMarkId.ring:
        canvas.drawCircle(center, r, paint);
        canvas.drawCircle(center, r * 0.55, paint);
      case GroupIconMarkId.chevron:
        final path = Path()
          ..moveTo(center.dx - r * 0.6, center.dy - r * 0.4)
          ..lineTo(center.dx, center.dy + r * 0.5)
          ..lineTo(center.dx + r * 0.6, center.dy - r * 0.4);
        canvas.drawPath(path, paint);
      case GroupIconMarkId.bolt:
        final path = Path()
          ..moveTo(center.dx + r * 0.15, center.dy - r)
          ..lineTo(center.dx - r * 0.35, center.dy + r * 0.05)
          ..lineTo(center.dx - r * 0.05, center.dy + r * 0.05)
          ..lineTo(center.dx - r * 0.25, center.dy + r)
          ..lineTo(center.dx + r * 0.45, center.dy - r * 0.15)
          ..lineTo(center.dx + r * 0.1, center.dy - r * 0.15)
          ..close();
        canvas.drawPath(path, fill);
      case GroupIconMarkId.monogram:
        break;
    }
  }

  Path _regularPolygon(Offset center, double radius, int sides,
      {double rotation = -1.5708}) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = rotation + (2 * 3.14159265 * i / sides);
      final point = Offset(
        center.dx + radius * _cos(angle),
        center.dy + radius * _sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  Path _starPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -1.5708 + i * 3.14159265 / 5;
      final r = i.isEven ? radius : radius * 0.45;
      final point = Offset(
        center.dx + r * _cos(angle),
        center.dy + r * _sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  double _cos(double radians) => _trig(radians, isCos: true);

  double _sin(double radians) => _trig(radians, isCos: false);

  double _trig(double radians, {required bool isCos}) {
    // Avoid importing dart:math for a tiny painter.
    var x = radians;
    while (x > 3.14159265) {
      x -= 2 * 3.14159265;
    }
    while (x < -3.14159265) {
      x += 2 * 3.14159265;
    }
    final x2 = x * x;
    if (isCos) {
      return 1 - x2 / 2 + x2 * x2 / 24;
    }
    return x - x * x2 / 6 + x * x2 * x2 / 120;
  }

  @override
  bool shouldRepaint(covariant _GroupMarkPainter oldDelegate) {
    return oldDelegate.markId != markId || oldDelegate.color != color;
  }
}
