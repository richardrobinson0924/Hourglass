import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

extension PathExtension on Path {
  Path withPoints(List<Point<double>> points) {
    Path path = this;
    path.moveTo(points[0].x, points[0].y);

    points.removeAt(0);
    points.forEach((p) => path.lineTo(p.x, p.y));
    path.close();

    return path;
  }
}

/// A generic Ratio class for quantifying a relationship between two Units
/// For consistency, `part` must be quantifiable and less than `total`. More
/// formally, `part.compareTo(total) < 0` must evaluate to true.
class Ratio<Quantity extends Comparable<Quantity>> {
  final Quantity part, total;

  Ratio({@required this.part, @required this.total})
      : assert (part  != null),
        assert (total != null),
        assert (part.compareTo(total) < 0);

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

    return other is Ratio<Quantity> && part == other.part && total == other.total;
  }

  @override
  int get hashCode => part.hashCode + 37 * total.hashCode;
}

class _FluidViewPainter extends CustomPainter {
  /// The gyroscopic roll value of the device
  final double angle;

  final Ratio<num> progress;
  final Color color;

  _FluidViewPainter({@required this.angle, @required this.progress, @required this.color})
      : assert(color != null && progress != null);

  @override
  void paint(Canvas canvas, Size size) {
    final fluidHeight = (progress.part / progress.total) * size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var tr = fluidHeight * angle + fluidHeight;

    var path = Path().withPoints([
      Point(0.0, size.height),
      Point(size.width, size.height),
      Point(size.width, tr),
      Point(0, fluidHeight * angle * -1 + fluidHeight)
    ]);

    canvas.drawPath(path, paint);
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