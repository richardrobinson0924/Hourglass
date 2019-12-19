import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBarDivider extends Divider implements PreferredSizeWidget {
  AppBarDivider({Key key, double height = 0.0, double indent = 0.0, Color color = Colors.white})
      : assert(height >= 0.0),
        super(key: key, height: height, indent: indent, color: color) {
    preferredSize = Size(double.infinity, height);
  }

  @override
  Size preferredSize;
}