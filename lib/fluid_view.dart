import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// A generic Ratio class for quantifying a relationship between two Units
/// For consistency, `part` must be quantifiable and less than `total`. More
/// formally, `part.compareTo(total) < 0` must evaluate to true.
class Ratio<Quantity extends Comparable<Quantity>> {
  final Quantity part, total;

  Ratio({@required this.part, @required this.total})
      : assert(part != null),
        assert(total != null),
        assert(part.compareTo(total) <= 0);

  /// Maps this Ratio to a Ratio of a possibly different type
  Ratio<R> map<R extends Comparable<R>>(R Function(Quantity) mapping) => Ratio(
      part: mapping(part),
      total: mapping(total)
  );


  @override
  String toString() => 'Ratio{${part.toString()} : ${total.toString()}}';

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Ratio<Quantity> &&
        part == other.part &&
        total == other.total;
  }

  @override
  int get hashCode => part.hashCode + 37 * total.hashCode;
}

class Polygon {
  final List<Point<double>> vertices;

  Polygon(this.vertices) : assert(vertices.length >= 3);

  Path get path {
    var ret = Path();
    ret.moveTo(vertices[0].x, vertices[0].y);

    for (int i = 1; i < vertices.length; i += 1) {
      ret.lineTo(vertices[i].x, vertices[i].y);
    }

    ret.close();
    return ret;
  }

  double get area {
    var ret = 0.0;
    var j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i += 1) {
      ret += (vertices[j].x + vertices[i].x) * (vertices[j].y - vertices[i].y);
      j = i;
    }

    return (ret / 2.0).abs();
  }
}

class _FluidViewPainter extends CustomPainter {
  final double angle;
  final Ratio<num> progress;
  final Color color;

  _FluidViewPainter({
    @required this.angle,
    @required this.progress,
    @required this.color
  }) : assert(color != null && progress != null);

  @override
  void paint(Canvas canvas, Size size) {
    final fluidHeight = (progress.part / progress.total) * size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final polygon = Polygon([
      Point(0.0, size.height),
      Point(size.width, size.height),
      Point(size.width, fluidHeight * angle + fluidHeight),
      Point(0, fluidHeight * angle * -1 + fluidHeight)
    ]);

    canvas.drawPath(polygon.path, paint);
  }

  @override
  bool shouldRepaint(_FluidViewPainter oldDelegate) =>
      !(oldDelegate.progress == progress) || oldDelegate.angle != angle;
}

class FluidView extends StatelessWidget {
  final double angle;
  final Color color;
  final Ratio<num> progress;

  const FluidView({
    Key key,
    @required this.angle,
    @required this.color,
    @required this.progress
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _FluidViewPainter(angle: angle, progress: progress, color: color)
  );
}
