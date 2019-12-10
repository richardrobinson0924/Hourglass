
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FillableContainer extends StatelessWidget {
  final double progress, size;
  final double pitch, roll;

  final Color backgroundColor;
  final Color progressColor;

  const FillableContainer({
    Key key,
    @required this.pitch,
    @required this.roll,
    @required this.backgroundColor,
    @required this.progressColor,
    @required this.progress,
    @required this.size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Stack(
      children: <Widget>[
        Container(color: progressColor),
        Transform(
          transform: Matrix4.identity(),
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(top: BorderSide(
                  color: Colors.white,
                  width: double.maxFinite
                ))
            ),
            height: (progress / size) * height,
          ),
        )
      ],
    );
  }

}