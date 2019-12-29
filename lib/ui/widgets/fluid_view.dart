import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class Polygon {
  final List<Point> vertices;

  /// A class representing an `n`-sides polygon where `n >= 3`
  Polygon(this.vertices) : assert(vertices.length >= 3);

  /// Returns [this] as a [Path] instance
  Path get path {
    var ret = Path();
    ret.moveTo(vertices[0].x.toDouble(), vertices[0].y.toDouble());

    for (int i = 1; i < vertices.length; i += 1) {
      ret.lineTo(vertices[i].x.toDouble(), vertices[i].y.toDouble());
    }

    ret.close();
    return ret;
  }

  /// Returns the area of [this]
  double get area {
    var ret = 0.0;
    var j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i += 1) {
      ret += (vertices[j].x + vertices[i].x) * (vertices[j].y - vertices[i].y);
      j = i;
    }

    return (ret / 2.0).abs();
  }

  @override
  String toString() =>
      'Polygon(points=\n\t[${vertices.map((v) => v.toString).join('\n\t')}\n])';
}

class _FluidViewPainter extends CustomPainter {
  final double angle;

  /// [0.0, 1.0]
  final double progress;
  final Color color;
  final Radius radius;

  _FluidViewPainter(
      {@required this.angle,
      @required this.progress,
      @required this.color,
      @required this.radius})
      : assert(color != null && progress != null),
        assert(progress >= 0.0 && progress <= 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final fluidHeight = progress * size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final polygon = Polygon([
      Point(0.0, size.height), // bottom left
      Point(size.width, size.height), // bottom right
      Point(size.width, fluidHeight * angle + fluidHeight), // top right
      Point(0, fluidHeight * angle * -1 + fluidHeight) // top left
    ]);

    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.0, 0.0, size.width, size.height), radius));

    canvas.drawPath(polygon.path, paint);
  }

  @override
  bool shouldRepaint(_FluidViewPainter oldDelegate) =>
      !(oldDelegate.progress == progress) || oldDelegate.angle != angle;
}

class FluidView extends StatelessWidget {
  /// Optionally, the [angle] of the device's roll value may be provided for the view to tilt accordingly
  final double angle;

  /// The color of the widget
  final Color color;

  /// The progress of how 'full' the widget is in the range `[0, 1]`
  /// The minimum value `0` denotes the widget's height be the height of [size].
  /// The maximum value `1` denotes the widget's height be 0.0
  final double progress;

  /// Optionally, the radius of the widget's corners can be specified.
  final Radius radius;

  /// The maximum possible size for the widget, with the height of the widget progressing from [size.height] down to `0.0`.
  /// If `null`, the size of the [BuildContext] is used.
  final Size size;

  FluidView(
      {Key key,
      @required this.color,
      @required this.progress,
      this.angle = 0.0,
      this.size,
      this.radius = Radius.zero})
      : assert(color != null),
        assert(progress >= 0.0 && progress <= 1.0),
        super(key: key);

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: size ?? MediaQuery.of(context).size,
      painter: _FluidViewPainter(
          angle: angle,
          progress: progress,
          color: color,
          radius: radius ?? Radius.zero));
}
