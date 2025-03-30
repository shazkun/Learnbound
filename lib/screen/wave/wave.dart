import 'dart:ui';

import 'package:flutter/material.dart';

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.4); // Start lower from the left

    // Create the smooth wave shape
    path.quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.7, // First curve control point
        size.width * 0.5,
        size.height * 0.6); // Midpoint

    path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.5, // Second curve control point
        size.width,
        size.height * 0.2); // End at the right side

    // Fill the remaining bottom part
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class TopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Start at top-left
    path.lineTo(0, size.height * 0.75);

    // First wave (left curve)
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.85,
        size.width * 0.5, size.height * 0.75);

    // Second wave (right curve)
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.65, size.width, size.height * 0.75);

    // Close at the top
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
