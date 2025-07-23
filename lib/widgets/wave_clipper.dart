import 'package:flutter/material.dart';

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40); // start from bottom-left before wave
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    ); // create wave curve
    path.lineTo(size.width, 0); // right top corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
