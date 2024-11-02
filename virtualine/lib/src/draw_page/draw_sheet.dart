import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../set_stats.dart';
import 'package:virtualine/search_directory.dart';
import 'dart:ui' as ui;

import 'components/drawable.dart';
import 'components/my_painter.dart';
import 'components/utils.dart';

class DrawSheet extends StatefulWidget {
  const DrawSheet({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DrawSheetState createState() => _DrawSheetState();
}

class _DrawSheetState extends State<DrawSheet> {
  List<Drawable> drawables = [];
  bool isErasing = false;
  Color selectedColor = Colors.black;
  double selectedWidth = 1.0;
  double opacity = 1.0;
  bool fullPaint = false;
  bool pipette = false;
  Color colorPipette = Colors.black;
  final GlobalKey _sheetKey = GlobalKey();
  final ValueNotifier<Offset?> mousePosition = ValueNotifier<Offset?>(null);
  TextEditingController customPathController = TextEditingController();
  TextEditingController projectNameController = TextEditingController();
  List<String> directoryList = [];
  String drawName = '';
  TextEditingController nameProjetController = TextEditingController();
  List<int> screenBuffer = List.filled(1400 * 800, Colors.white.value);

  @override
  void initState() {
    super.initState();
    _initListeners();
    _loadInitialData();
  }

  void _initListeners() {
    eraserState.addListener(_updateErasing);
    colorState.addListener(_updateColor);
    widthState.addListener(_updateWidth);
    opacityState.addListener(_updateOpacity);
    fullPaintState.addListener(_updateFullPaint);
    pipetteState.addListener(_updatePipette);
  }

  void _loadInitialData() {
    loadPathProject(customPathController, _listDirectories);
    loadProjectName(projectNameController);
  }

  void _listDirectories(String pathString) {
    setState(() {
      directoryList = listDirectories(pathString);
    });
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  void _removeListeners() {
    eraserState.removeListener(_updateErasing);
    colorState.removeListener(_updateColor);
    widthState.removeListener(_updateWidth);
    opacityState.removeListener(_updateOpacity);
    fullPaintState.removeListener(_updateFullPaint);
    pipetteState.removeListener(_updatePipette);
  }

  void _updateErasing() {
    setState(() {
      isErasing = eraserState.value;
      selectedColor = isErasing ? Colors.white : Color(colorState.value);
    });
  }

  void _updateColor() {
    setState(() {
      selectedColor = isErasing ? Colors.white : Color(colorState.value);
    });
  }

  void _updateWidth() {
    setState(() {
      selectedWidth = widthState.value;
    });
  }

  void _updateOpacity() {
    setState(() {
      opacity = isErasing ? 1.0 : opacityState.value;
    });
  }

  void _updateFullPaint() {
    setState(() {
      fullPaint = fullPaintState.value;
    });
  }

  void _updatePipette() {
    setState(() {
      pipette = pipetteState.value;
    });
  }

  Future<void> saveDrawing() async {
    await Future.delayed(const Duration(milliseconds: 100));

    RenderRepaintBoundary boundary =
        _sheetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    String dir =
        '${customPathController.text}/${projectNameController.text}/assets/dessin';
    String fullPath = '$dir/$drawName.png';

    if (File(fullPath).existsSync()) {
      _showErrorDialog('Erreur', 'Un dessin avec ce nom existe déjà');
    } else {
      File imgFile = File(fullPath);
      imgFile.writeAsBytes(pngBytes);
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                nameProject();
              },
            ),
          ],
        );
      },
    );
  }

  void nameProject() {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Comment voulez-vous nommer votre dessin ?'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameProjetController,
              decoration: const InputDecoration(hintText: 'Nom du dessin'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom de dessin';
                }
                return null;
              },
              onFieldSubmitted: (value) {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    drawName = nameProjetController.text;
                    Navigator.of(context).pop();
                  });
                  saveDrawing();
                }
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Valider'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    drawName = nameProjetController.text;
                    Navigator.of(context).pop();
                  });
                  saveDrawing();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Container(
          width: 1400,
          height: 800, 
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),           
          ),
          child: MouseRegion(
            onEnter: (event) {
              final RenderBox renderBox =
                  _sheetKey.currentContext!.findRenderObject() as RenderBox;
              final Offset localPosition =
                  renderBox.globalToLocal(event.position);
              mousePosition.value = localPosition;
            },
            onHover: (event) {
              final RenderBox renderBox =
                  _sheetKey.currentContext!.findRenderObject() as RenderBox;
              final Offset localPosition =
                  renderBox.globalToLocal(event.position);
              mousePosition.value = localPosition;
            },
            onExit: (event) {
              mousePosition.value = null;
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapDown: _onTapDown,
                child: RepaintBoundary(
                  key: _sheetKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          ClipRect(
                            child: CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              painter: MyPainter(drawables: drawables),
                            ),
                          ),
                          _buildCursor(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.save, color: Colors.purple, size: 20),
          onPressed: nameProject,
          tooltip: 'Sauvegarder',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minHeight: 36,
            minWidth: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildCursor() {
    return ValueListenableBuilder<Offset?>(
      valueListenable: mousePosition,
      builder: (context, mousePosition, child) {
        if (mousePosition == null) return const SizedBox.shrink();
        return Positioned(
          left: mousePosition.dx - selectedWidth / 2,
          top: mousePosition.dy - selectedWidth / 2,
          child: Container(
            width: selectedWidth,
            height: selectedWidth,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedWidth == 1.0 ? selectedColor : null,
              border: Border.all(color: Colors.black54, width: 1),
            ),
          ),
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
    RenderBox renderBox =
        _sheetKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    if (fullPaint) {
      return;
    }

    setState(() {
      drawables.add(Drawable(
          path: Path()..moveTo(localPosition.dx, localPosition.dy),
          paint: Paint()
            ..color = selectedColor.withOpacity(opacity)
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..strokeWidth = selectedWidth,
          points: [localPosition]));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (fullPaint) {
      return;
    }

    RenderBox renderBox =
        _sheetKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    int lastIndex = drawables.length - 1;

    double distance =
        (drawables[lastIndex].points.last - localPosition).distance;
    if (distance > 2.0) {
      setState(() {
        drawables[lastIndex].points.add(localPosition);
        if (drawables[lastIndex].points.length > 2) {
          Offset p1 = drawables[lastIndex]
              .points[drawables[lastIndex].points.length - 2];
          Offset p2 = drawables[lastIndex].points.last;
          Offset controlPoint =
              Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          drawables[lastIndex].path.quadraticBezierTo(
              p1.dx, p1.dy, controlPoint.dx, controlPoint.dy);
        } else {
          drawables[lastIndex].path.lineTo(localPosition.dx, localPosition.dy);
        }
        mousePosition.value = localPosition;

        int x1 = drawables[lastIndex]
            .points[drawables[lastIndex].points.length - 2]
            .dx
            .toInt();
        int y1 = drawables[lastIndex]
            .points[drawables[lastIndex].points.length - 2]
            .dy
            .toInt();
        int x2 = localPosition.dx.toInt();
        int y2 = localPosition.dy.toInt();

        _drawLineOnBuffer(x1, y1, x2, y2, selectedColor);
      });
    }
  }

  void _drawLineOnBuffer(int x1, int y1, int x2, int y2, Color color) {
    int dx = (x2 - x1).abs();
    int dy = (y2 - y1).abs();
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;

    while (true) {
      if (x1 >= 0 && x1 < 1400 && y1 >= 0 && y1 < 800) {
        screenBuffer[y1 * 1400 + x1] = color.value;
      }

      if (x1 == x2 && y1 == y2) break;
      int e2 = err * 2;
      if (e2 > -dy) {
        err -= dy;
        x1 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y1 += sy;
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {}

  void _onTapDown(TapDownDetails details) {
    RenderBox renderBox =
        _sheetKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    int index = localPosition.dy.toInt() * 1400 + localPosition.dx.toInt();

    if (index >= 0 && index < screenBuffer.length) {
      debugPrint('Tapped at position: $localPosition with index $index');
      debugPrint('Color at position: ${Color(screenBuffer[index])}');

      if (pipette) {
        setState(() {
          colorPipette = Color(screenBuffer[index]);
          colorState.value = colorPipette.value;
          debugPrint('Picked color: $colorPipette');
        });
      }

      if (fullPaint) {
        floodFill(
            localPosition.dx.toInt(),
            localPosition.dy.toInt(),
            selectedColor.value,
            screenBuffer[index],
            screenBuffer,
            1400,
            800,
            drawables,
            setState,
            selectedWidth);
      }
    } else {
      debugPrint('Index out of bounds: $index');
    }
  }
}
