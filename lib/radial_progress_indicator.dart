import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class _CircleProgress extends CustomPainter {
  final Color color;
  final Color backgroundColor;
  final double progress;

  _CircleProgress(this.progress, this.color, this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final outerCircle = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final completeArc = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, outerCircle);

    final angle = 2 * pi * progress;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -pi / 2, angle, false);

    canvas.drawPath(path, completeArc);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class RadialProgressIndicator extends StatelessWidget {
  final Color color;
  final Color backgroundColor;

  /// The value of the progress in the range `[0, 1]`. If given an out of range value,
  /// the progress is clamped to the acceptable range according to:
  ///
  /// If [progress] > 1.0 (including `Infinity`) or `NaN`, clamp to `1.0`;
  /// If [progress] < 0.0, clamp to `0.0`
  final double progress;
  final double radius;

  RadialProgressIndicator(
      {Key key,
      this.color,
      this.backgroundColor,
      @required this.radius,
      @required this.progress})
      : assert(radius > 0.0),
        super(key: key);

  double get _clampedProgress =>
      (!progress.isFinite) ? 1.0 : min(1.0, progress);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      alignment: Alignment.center,
      width: radius * 2,
      height: radius * 2,
      child: CustomPaint(
          painter: _CircleProgress(
              _clampedProgress,
              color ?? theme.primaryColor,
              backgroundColor ?? theme.backgroundColor),
          size: Size.fromRadius(radius)),
    );
  }
}
