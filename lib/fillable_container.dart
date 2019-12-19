
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CircleButton extends InkResponse {
  CircleButton({
    Key key,
    @required Color color,
    @required double radius,
    @required GestureTapCallback onTap
  }) : super(
      key: key,
      child: Circle(color: color, radius: radius),
      onTap: onTap
  );
}

class Circle extends StatelessWidget {
  final Color color;
  final double radius;

  const Circle({
    Key key,
    @required this.color,
    @required this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle
    ),
  );
}
