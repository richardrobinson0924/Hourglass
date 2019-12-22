import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CircleButton extends InkResponse {
  final Color color;
  final double radius;
  final void Function() onTap;

  CircleButton(
      {Key key,
      @required this.color,
      @required this.radius,
      @required this.onTap})
      : super(
            key: key,
            child: Circle(color: color, radius: radius),
            onTap: onTap);
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
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
