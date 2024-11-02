import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'drawable.dart';

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

void floodFill(
  int x,
  int y,
  int newColor,
  int oldColor,
  List<int> screenBuffer,
  int w,
  int h,
  List<Drawable> drawables,
  Function setState,
  double width
) async {
  if (oldColor == newColor) return;

  ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(
    _floodFillIsolate,
    [
      x,
      y,
      newColor,
      oldColor,
      screenBuffer,
      w,
      h,
      receivePort.sendPort,
    ],
  );

  List<Rect> filledRects = await receivePort.first;

  setState(() {
    for (Rect rect in filledRects) {
      Path path = Path();
      path.moveTo(rect.left, rect.top);
      path.lineTo(rect.right, rect.top);
      path.lineTo(rect.right, rect.bottom);
      path.lineTo(rect.left, rect.bottom);
      path.close(); 

      Drawable drawable = Drawable(
        path: path,
        paint: Paint()
          ..color = Color(newColor),
        points: [],
      );
      drawables.add(drawable);
    }
  });
}


void _floodFillIsolate(List args) {
  int x = args[0];
  int y = args[1];
  int newColor = args[2];
  int oldColor = args[3];
  List<int> screenBuffer = args[4];
  int w = args[5];
  int h = args[6];
  SendPort sendPort = args[7];

  Queue<Point> stack = Queue();
  List<bool> visited = List.filled(w * h, false);
  List<Rect> filledRects = [];

  stack.add(Point(x, y));
  visited[y * w + x] = true;

  while (stack.isNotEmpty) {
    Point p = stack.removeLast();
    x = p.x;
    y = p.y;

    int x1 = x;
    while (x1 >= 0 && screenBuffer[y * w + x1] == oldColor) {
      x1--;
    }
    x1++;
    bool spanAbove = false, spanBelow = false;
    while (x1 < w && screenBuffer[y * w + x1] == oldColor) {
      screenBuffer[y * w + x1] = newColor;
      if (!spanAbove && y > 0 && screenBuffer[(y - 1) * w + x1] == oldColor) {
        if (!visited[(y - 1) * w + x1]) {
          stack.add(Point(x1, y - 1));
          visited[(y - 1) * w + x1] = true;
        }
        spanAbove = true;
      } else if (spanAbove && y > 0 && screenBuffer[(y - 1) * w + x1] != oldColor) {
        spanAbove = false;
      }
      if (!spanBelow && y < h - 1 && screenBuffer[(y + 1) * w + x1] == oldColor) {
        if (!visited[(y + 1) * w + x1]) {
          stack.add(Point(x1, y + 1));
          visited[(y + 1) * w + x1] = true;
        }
        spanBelow = true;
      } else if (spanBelow && y < h - 1 && screenBuffer[(y + 1) * w + x1] != oldColor) {
        spanBelow = false;
      }
      x1++;
    }
  }

  for (int i = 0; i < h; i++) {
    int start = -1;
    for (int j = 0; j < w; j++) {
      if (screenBuffer[i * w + j] == newColor) {
        if (start == -1) start = j;
      } else {
        if (start != -1) {
          filledRects.add(Rect.fromLTWH(start.toDouble(), i.toDouble(), (j - start).toDouble(), 1));
          start = -1;
        }
      }
    }
    if (start != -1) {
      filledRects.add(Rect.fromLTWH(start.toDouble(), i.toDouble(), (w - start).toDouble(), 1));
    }
  }

  sendPort.send(filledRects);
}

class DrawablePainter extends CustomPainter {
  final List<Drawable> drawables;

  DrawablePainter(this.drawables);

  @override
  void paint(Canvas canvas, Size size) {
    for (Drawable drawable in drawables) {
      canvas.drawPath(drawable.path, drawable.paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
