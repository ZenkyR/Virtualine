import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'drawable.dart';

class MyPainter extends CustomPainter {
  final List<Drawable> drawables;

  MyPainter({required this.drawables});

  @override
  void paint(Canvas canvas, Size size) {
    final buffer = ui.PictureRecorder();
    final bufferCanvas = Canvas(buffer);

    for (final drawable in drawables) {
      bufferCanvas.drawPath(drawable.path, drawable.paint);
    }

    canvas.drawPicture(buffer.endRecording());
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return drawables != oldDelegate.drawables;
  }
}
