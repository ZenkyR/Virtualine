import 'dart:ui';

class Drawable {
  Path path;
  Paint paint;
  List<Offset> points;

  Drawable({required this.path, required this.paint, required this.points});
}
