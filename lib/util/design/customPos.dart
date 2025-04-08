import 'package:flutter/material.dart';

class CustomFabLocation extends FloatingActionButtonLocation {
  final double offsetX;
  final double offsetY;

  CustomFabLocation(this.offsetX, this.offsetY);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        offsetX -
        scaffoldGeometry.floatingActionButtonSize.width;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        offsetY -
        scaffoldGeometry.floatingActionButtonSize.height;
    return Offset(fabX, fabY);
  }
}
