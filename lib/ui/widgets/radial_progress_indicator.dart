import 'dart:math';
import 'dart:ui';

import 'package:countdown/model/model.dart';
import 'package:flutter/material.dart';

class _Wedge extends CustomPainter {
  final Color color;
  final double progress;

  _Wedge({@required this.progress, @required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final completeArc = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final angle = 2 * pi * progress;

    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -pi / 2, angle, false);

    canvas.drawPath(path, completeArc);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Similar to [CircularProgressIndicator], except it shows the progress in terms
/// of a circular fill instead of border. Additionally, changes appearance when
/// the progress is out of range `[0. 1]`
class RadialProgressIndicator extends StatelessWidget {
  final Color color;
  final Color backgroundColor;

  /// The value of the progress in the range `[0, 1]`. All values outside of this range,
  /// or non-finite, are considered 'complete'
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.primaryColor;

    return Semantics(
      label: 'Progress indicator',
      value: '${progress <= 0.0 ? 0.0 : progress * 100.0}% remaining',
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Circle(
              radius: radius, color: backgroundColor ?? theme.backgroundColor),
          (progress > 1.0 || progress <= 0.0)
              ? Container(child: Icon(Icons.check, color: fg))
              : CustomPaint(
                  painter: _Wedge(
                      progress: !progress.isFinite ? 1.0 : progress, color: fg),
                  size: Size.fromRadius(radius))
        ],
      ),
    );
  }
}
