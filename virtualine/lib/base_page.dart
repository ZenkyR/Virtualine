// ignore_for_file: unused_field

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:virtualine/set_object.dart';
import 'package:virtualine/search_directory.dart';
import 'package:flame/game.dart';
import 'package:virtualine/src/game_page/game_page.dart';

const double _kMinScale = 0.1;
const double _kMaxScale = 10.0;
const double _kScaleIncrement = 1.2;
const double _kDefaultObjectSize = 128.0;
const double _kPlayerWidth = 128.0;
const double _kPlayerHeight = 100.0;
const double _kGridSize = 32.0;
const double _kGridOpacity = 0.5;

enum PlacementMode { single, fill, defineEnemyPath }

// Custom types
typedef DirectoryListCallback = void Function(String path);

class ViewportState {
  final bool isDragging;
  final Offset lastFocalPoint;
  final double currentScale;
  final Size viewportSize;
  final bool showGrid;
  final PlacementMode placementMode;
  final Offset? fillStart;
  final Offset? fillEnd;
  final List<Point> currentPath;

  const ViewportState({
    this.isDragging = false,
    this.lastFocalPoint = Offset.zero,
    this.currentScale = 1.0,
    this.viewportSize = Size.zero,
    this.showGrid = false,
    this.placementMode = PlacementMode.single,
    this.fillStart,
    this.fillEnd,
    this.currentPath = const [],
  });

  ViewportState copyWith({
    bool? isDragging,
    Offset? lastFocalPoint,
    double? currentScale,
    Size? viewportSize,
    bool? showGrid,
    PlacementMode? placementMode,
    Offset? fillStart,
    Offset? fillEnd,
    List<Point>? currentPath,
  }) {
    return ViewportState(
      isDragging: isDragging ?? this.isDragging,
      lastFocalPoint: lastFocalPoint ?? this.lastFocalPoint,
      currentScale: currentScale ?? this.currentScale,
      viewportSize: viewportSize ?? this.viewportSize,
      showGrid: showGrid ?? this.showGrid,
      placementMode: placementMode ?? this.placementMode,
      fillStart: fillStart ?? this.fillStart,
      fillEnd: fillEnd ?? this.fillEnd,
      currentPath: currentPath ?? this.currentPath,
    );
  }
}

abstract class BasePage extends StatefulWidget {
  final ValueNotifier<List<ImageWidgetInfo>> imageWidgetsInfoNotifier;
  final bool disableZoom;
  final bool isGameMode;

  const BasePage({
    super.key,
    required this.imageWidgetsInfoNotifier,
    this.disableZoom = false,
    this.isGameMode = false,
  });

  @override
  BasePageState createState() => BasePageState();

  Widget buildContent(BuildContext context);
  GameWidget<MyGame>? createGame();
}

class BasePageState extends State<BasePage> {
  // Controllers
  late final TransformationController _transformationController;
  late final TextEditingController _customPathController;
  late final TextEditingController _projectNameController;
  final GlobalKey _containerKey = GlobalKey();

  // State
  late ViewportState _viewportState;
  ImageWidgetInfo? _selectedObject;
  List<String> _directoryList = [];

  // Player state
  String? _playerPath;
  double _playerX = 0.0;
  double _playerY = 0.0;

  Offset _dragOffset = Offset.zero;
  String? _selectedTilePath;
  bool _isFillingArea = false;
  ImageWidgetInfo? _selectedEnemy;
  Offset? _previewPoint;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeViewportState();
    _setupListeners();
    _loadInitialData();
    _initPlayerState();
  }

  void _initPlayerState() {
    _playerPath = GameDataManager().playerState.value.path;
    _playerX = GameDataManager().playerState.value.x;
    _playerY = GameDataManager().playerState.value.y;
  }

  void _initializeControllers() {
    _transformationController = TransformationController();
    _customPathController = TextEditingController();
    _projectNameController = TextEditingController();
  }

  void _initializeViewportState() {
    _viewportState = const ViewportState();
    GameDataManager().initialize().then((_) {
      _updatePlayerStateFromManager();
      _updateImagesStateFromManager();
    });
  }

  void _updatePlayerStateFromManager() {
    setState(() {
      _playerPath = GameDataManager().playerState.value.path;
      _playerX = GameDataManager().playerState.value.x;
      _playerY = GameDataManager().playerState.value.y;
    });
  }

  void _updateImagesStateFromManager() {
    setState(() {
      widget.imageWidgetsInfoNotifier.value.clear();
      for (final info in GameDataManager().imagesState.value) {
        if (info is GroupedImageInfo) {
          widget.imageWidgetsInfoNotifier.value.add(GroupedImageInfo(
            path: info.path,
            name: info.name,
            x: info.x,
            y: info.y,
            width: info.width,
            height: info.height,
            tiles: info.tiles,
            gridSize: info.gridSize,
            collision: info.collision,
          ));
        } else {
          widget.imageWidgetsInfoNotifier.value.add(info);
        }
      }
    });
  }

  void _setupListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateViewportSize());
    GameDataManager().playerState.addListener(_handlePlayerStateChange);
  }

  void _loadInitialData() {
    void updateDirectoryList(String path) {
      setState(() => _directoryList = listDirectories(path));
    }

    loadPathProject(_customPathController, updateDirectoryList);
    loadProjectName(_projectNameController);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _customPathController.dispose();
    _projectNameController.dispose();
    GameDataManager().playerState.removeListener(_handlePlayerStateChange);
    super.dispose();
  }

  void _handlePlayerStateChange() {
    if (!mounted) return;

    setState(() {
      _playerPath = GameDataManager().playerState.value.path;
      _playerX = GameDataManager().playerState.value.x;
      _playerY = GameDataManager().playerState.value.y;
    });
  }

  void _updateViewportSize() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _viewportState = _viewportState.copyWith(
          viewportSize: renderBox.size,
        );
      });
    }
  }

  void _applyTransformation(Offset focalPoint, double scale) {
    final double visibleWidth = _viewportState.viewportSize.width / scale;
    final double visibleHeight = _viewportState.viewportSize.height / scale;

    final double newX = focalPoint.dx.clamp(
      0,
      20000 - visibleWidth,
    );
    final double newY = focalPoint.dy.clamp(
      0,
      20000 - visibleHeight,
    );

    _transformationController.value = Matrix4.identity()
      ..translate(newX, newY)
      ..scale(scale)
      ..translate(-focalPoint.dx, -focalPoint.dy);
  }

  List<Widget> _buildImageWidgets() {
    return widget.imageWidgetsInfoNotifier.value
        .map((info) => _buildDraggableImage(info))
        .toList();
  }

  Widget _buildDraggableImage(ImageWidgetInfo info) {
    final isSelected = _selectedObject == info || _selectedEnemy == info;

    if (info is GroupedImageInfo) {
      return Positioned(
        left: info.x,
        top: info.y,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _selectedObject = info;
                _viewportState = _viewportState.copyWith(isDragging: true);
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                final scenePoint =
                    _transformationController.toScene(localPosition);
                _dragOffset =
                    Offset(info.x - scenePoint.dx, info.y - scenePoint.dy);
              });
            },
            onPanUpdate: (details) => _handleImageDragUpdate(details, info),
            onPanEnd: (_) => _handleImageDragEnd(),
            child: SizedBox(
              width: info.gridSize.width,
              height: info.gridSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final tile in info.tiles)
                    Positioned(
                      left: tile.relativeX,
                      top: tile.relativeY,
                      child: Container(
                        width: _kDefaultObjectSize,
                        height: _kDefaultObjectSize,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(File(info.path)),
                            fit: BoxFit.cover,
                          ),
                          border: isSelected
                              ? Border.all(color: Colors.purple, width: 2)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: info.x,
      top: info.y,
      width: info.width,
      height: info.height,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          onTap: () {
            if (info.isEnemy &&
                _viewportState.placementMode == PlacementMode.defineEnemyPath) {
              setState(() {
                _selectedEnemy = info;
                _viewportState = _viewportState.copyWith(
                  currentPath: info.movementPath,
                );
              });
            }
          },
          onPanStart: (details) {
            setState(() {
              _selectedObject = info;
              _viewportState = _viewportState.copyWith(isDragging: true);
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition =
                  renderBox.globalToLocal(details.globalPosition);
              final scenePoint =
                  _transformationController.toScene(localPosition);
              _dragOffset =
                  Offset(info.x - scenePoint.dx, info.y - scenePoint.dy);
            });
          },
          onPanUpdate: (details) => _handleImageDragUpdate(details, info),
          onPanEnd: (_) => _handleImageDragEnd(),
          child: _buildImageContainer(info, isSelected),
        ),
      ),
    );
  }

  Widget _buildImageContainer(ImageWidgetInfo info, bool isSelected) {
    return Container(
      width: _kDefaultObjectSize,
      height: _kDefaultObjectSize,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(info.path)),
          fit: BoxFit.cover,
        ),
        border: isSelected ? Border.all(color: Colors.purple, width: 2) : null,
      ),
    );
  }

  Offset _snapToGrid(double x, double y) {
    if (!_viewportState.showGrid) return Offset(x, y);

    final snapSize = _viewportState.placementMode == PlacementMode.fill
        ? _kDefaultObjectSize
        : _kGridSize;

    return Offset(
      (x / snapSize).round() * snapSize,
      (y / snapSize).round() * snapSize,
    );
  }

  void _handleGridTap(Offset position) {
    if (_viewportState.placementMode != PlacementMode.defineEnemyPath ||
        _selectedEnemy == null ||
        !_selectedEnemy!.isEnemy) return;

    final snappedPosition = _snapToGrid(position.dx, position.dy);
    setState(() {
      _selectedEnemy!.movementPath
          .add(Point(snappedPosition.dx, snappedPosition.dy));
      _viewportState = _viewportState.copyWith(
        currentPath: List<Point>.from(_selectedEnemy!.movementPath),
      );
    });
  }

  Widget _buildPathPreview() {
    if (_viewportState.placementMode != PlacementMode.defineEnemyPath) {
      return Container();
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (event) {
        if (_viewportState.placementMode == PlacementMode.defineEnemyPath) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(event.position);
          final scenePoint = _transformationController.toScene(localPosition);
          setState(() {
            _previewPoint = _snapToGrid(scenePoint.dx, scenePoint.dy);
          });
        }
      },
      onExit: (event) {
        setState(() {
          _previewPoint = null;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          final scenePoint = _transformationController.toScene(localPosition);
          _handleGridTap(scenePoint);
        },
        child: CustomPaint(
          size: const Size(20000, 20000),
          painter: PathPainter(
            points: _viewportState.currentPath,
            previewPoint: _previewPoint,
            color: Colors.purple,
          ),
        ),
      ),
    );
  }

  Widget _buildEnemyPathButton() {
    return PopupMenuButton(
      icon: Icon(
        Icons.route,
        color: _viewportState.placementMode == PlacementMode.defineEnemyPath
            ? Colors.purple
            : Colors.white,
      ),
      onSelected: (value) {
        switch (value) {
          case 'define':
            setState(() {
              _viewportState = _viewportState.copyWith(
                placementMode: PlacementMode.defineEnemyPath,
                currentPath: _selectedEnemy?.movementPath ?? [],
              );
            });
            break;
          case 'clear':
            _clearEnemyPath();
            break;
          case 'save':
            _saveEnemyPath();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'define',
          child: Text('Définir le chemin'),
        ),
        const PopupMenuItem(
          value: 'clear',
          child: Text('Effacer le chemin'),
        ),
        const PopupMenuItem(
          value: 'save',
          child: Text('Sauvegarder le chemin'),
        ),
      ],
    );
  }

  void _clearEnemyPath() {
    if (_selectedEnemy != null) {
      setState(() {
        _selectedEnemy!.movementPath.clear();
        _viewportState = _viewportState.copyWith(
          currentPath: [],
        );
      });
    }
  }

  void _saveEnemyPath() {
    if (_selectedEnemy == null || _viewportState.currentPath.isEmpty) return;

    setState(() {
      _selectedEnemy!.movementPath = List.from(_viewportState.currentPath);
      _viewportState = _viewportState.copyWith(
        placementMode: PlacementMode.single,
        currentPath: [],
      );
      _selectedEnemy = null;
    });

    GameDataManager().saveImages(widget.imageWidgetsInfoNotifier.value);
  }

  void _handleImageDragUpdate(DragUpdateDetails details, ImageWidgetInfo info) {
    if (!_viewportState.isDragging) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final scenePoint = _transformationController.toScene(localPosition);

    final snappedPosition = _snapToGrid(
      scenePoint.dx + _dragOffset.dx,
      scenePoint.dy + _dragOffset.dy,
    );

    setState(() {
      info.x = snappedPosition.dx.clamp(0, 20000 - _kDefaultObjectSize);
      info.y = snappedPosition.dy.clamp(0, 20000 - _kDefaultObjectSize);
    });
  }

  void _handleImageDragEnd() {
    setState(() {
      _selectedObject = null;
      _viewportState = _viewportState.copyWith(isDragging: false);
      _dragOffset = Offset.zero;
    });
    GameDataManager().saveImages(widget.imageWidgetsInfoNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: widget.isGameMode ? _buildGameArea() : _buildEditArea(),
    );
  }

  Widget _buildEditArea() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DragTarget<List<dynamic>>(
          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              onPanStart: (details) {
                if (_viewportState.placementMode == PlacementMode.fill &&
                    _viewportState.fillStart == null) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final localPosition =
                      renderBox.globalToLocal(details.globalPosition);
                  final scenePoint =
                      _transformationController.toScene(localPosition);
                  _handleGridTap(scenePoint);
                  setState(() {
                    _viewportState = _viewportState.copyWith(
                      fillStart: _snapToGrid(scenePoint.dx, scenePoint.dy),
                      fillEnd: _snapToGrid(scenePoint.dx, scenePoint.dy),
                    );
                  });
                }
              },
              onPanUpdate: (details) {
                if (_viewportState.placementMode == PlacementMode.fill &&
                    _viewportState.fillStart != null) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final localPosition =
                      renderBox.globalToLocal(details.globalPosition);
                  final scenePoint =
                      _transformationController.toScene(localPosition);
                  setState(() {
                    _viewportState = _viewportState.copyWith(
                      fillEnd: _snapToGrid(scenePoint.dx, scenePoint.dy),
                    );
                  });
                }
              },
              onPanEnd: (details) {
                if (_viewportState.placementMode == PlacementMode.fill &&
                    _viewportState.fillStart != null &&
                    _viewportState.fillEnd != null) {
                  _handleFillEnd(_viewportState.fillEnd!);
                }
              },
              child: SizedBox.expand(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: _kMinScale,
                  maxScale: _kMaxScale,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  constrained: false,
                  panEnabled: true,
                  scaleEnabled: true,
                  onInteractionStart: (details) {
                    if (_viewportState.placementMode != PlacementMode.fill ||
                        _viewportState.fillStart == null) {
                      setState(() {
                        _viewportState = _viewportState.copyWith(
                          lastFocalPoint: details.focalPoint,
                        );
                      });
                    }
                  },
                  onInteractionUpdate: (details) {
                    if (_viewportState.placementMode != PlacementMode.fill ||
                        _viewportState.fillStart == null) {
                      setState(() {
                        _viewportState = _viewportState.copyWith(
                          lastFocalPoint: details.focalPoint,
                          currentScale: details.scale,
                        );
                      });
                    }
                  },
                  child: SizedBox(
                    width: 20000,
                    height: 20000,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        _buildGrid(),
                        widget.buildContent(context),
                        _buildFillPreview(),
                        ..._buildImageWidgets(),
                        _buildPlayer(),
                        if (_viewportState.placementMode ==
                                PlacementMode.defineEnemyPath &&
                            _selectedEnemy != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: false,
                              child: _buildPathPreview(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          onAcceptWithDetails: _handleDragAccept,
        ),
        Positioned.fill(
          child: Stack(
            children: [
              _buildZoomControls(),
              _buildModeControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeControls() {
    return Positioned(
      left: 16,
      bottom: 16,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'placementMode',
            onPressed: () {
              setState(() {
                _viewportState = _viewportState.copyWith(
                  placementMode:
                      _viewportState.placementMode == PlacementMode.single
                          ? PlacementMode.fill
                          : PlacementMode.single,
                  fillStart: null,
                  fillEnd: null,
                  currentPath: [],
                );
              });
            },
            tooltip: _viewportState.placementMode == PlacementMode.single
                ? 'Switch to Fill Mode'
                : 'Switch to Single Mode',
            child: Icon(_viewportState.placementMode == PlacementMode.single
                ? Icons.crop_square
                : Icons.grid_on),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'enemyPathMode',
            onPressed: () {
              setState(() {
                if (_viewportState.placementMode ==
                    PlacementMode.defineEnemyPath) {
                  _saveEnemyPath();
                } else {
                  _viewportState = _viewportState.copyWith(
                    placementMode: PlacementMode.defineEnemyPath,
                    currentPath: _selectedEnemy?.movementPath ?? [],
                  );
                }
              });
            },
            tooltip: 'Define Enemy Path',
            backgroundColor:
                _viewportState.placementMode == PlacementMode.defineEnemyPath
                    ? Colors.purple
                    : null,
            child: const Icon(Icons.route),
          ),
          const SizedBox(height: 8),
          _buildGridButton(),
          _buildEnemyPathButton(),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    final game = widget.createGame();
    if (game == null) return Container();
    return game;
  }

  Widget _buildGrid() {
    if (!_viewportState.showGrid) return Container();

    return CustomPaint(
      size: const Size(20000, 20000),
      painter: GridPainter(
        gridSize: _kGridSize,
        opacity: _kGridOpacity,
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        children: [
          _buildZoomButton('zoomIn', Icons.add, _handleZoomIn),
          const SizedBox(height: 8),
          _buildZoomButton('zoomOut', Icons.remove, _handleZoomOut),
          const SizedBox(height: 8),
          _buildZoomButton(
              'reset', Icons.center_focus_strong, _handleResetView),
          const SizedBox(height: 8),
          _buildStartButton('start', Icons.play_arrow, _handleStart),
        ],
      ),
    );
  }

  Widget _buildGridButton() {
    return FloatingActionButton(
      heroTag: 'grid',
      onPressed: () {
        setState(() {
          _viewportState = _viewportState.copyWith(
            showGrid: !_viewportState.showGrid,
          );
        });
      },
      child: Icon(_viewportState.showGrid ? Icons.grid_on : Icons.grid_off),
    );
  }

  Widget _buildStartButton(String tag, IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      heroTag: tag,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Widget _buildZoomButton(String tag, IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      heroTag: tag,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  void _handleZoomIn() => _zoom(_kScaleIncrement);
  void _handleZoomOut() => _zoom(1 / _kScaleIncrement);
  void _handleResetView() =>
      _transformationController.value = Matrix4.identity();
  void _handleStart() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GamePage(
              imageWidgetsInfoNotifier: widget.imageWidgetsInfoNotifier)));

  void _zoom(double factor) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(_kMinScale, _kMaxScale);

    if (newScale != currentScale) {
      final focalPointScene =
          _transformationController.toScene(_viewportState.lastFocalPoint);
      _applyTransformation(focalPointScene, newScale);
    }
  }

  void _handleFillEnd(Offset endPoint) {
    if (_selectedTilePath == null || _viewportState.fillStart == null) return;

    final start = _viewportState.fillStart!;
    final end = _snapToGrid(endPoint.dx, endPoint.dy);

    final startX = min(start.dx, end.dx);
    final endX = max(start.dx, end.dx);
    final startY = min(start.dy, end.dy);
    final endY = max(start.dy, end.dy);

    final tilesX = ((endX - startX) / _kDefaultObjectSize).ceil();
    final tilesY = ((endY - startY) / _kDefaultObjectSize).ceil();

    final tiles = <TileInfo>[];
    for (int i = 0; i <= tilesX; i++) {
      for (int j = 0; j <= tilesY; j++) {
        tiles.add(TileInfo(
          i * _kDefaultObjectSize,
          j * _kDefaultObjectSize,
        ));
      }
    }

    final groupedImage = GroupedImageInfo(
      path: _selectedTilePath!,
      name: 'Group ${widget.imageWidgetsInfoNotifier.value.length + 1}',
      x: startX,
      y: startY,
      width: (tilesX + 1) * _kDefaultObjectSize,
      height: (tilesY + 1) * _kDefaultObjectSize,
      tiles: tiles,
      gridSize: Size(
        (tilesX + 1) * _kDefaultObjectSize,
        (tilesY + 1) * _kDefaultObjectSize,
      ),
    );

    setState(() {
      final updatedList =
          List<ImageWidgetInfo>.from(widget.imageWidgetsInfoNotifier.value)
            ..add(groupedImage);

      widget.imageWidgetsInfoNotifier.value = updatedList;
      _viewportState = _viewportState.copyWith(
        fillStart: null,
        fillEnd: null,
      );
      _selectedTilePath = null;
    });
    GameDataManager().saveImages(widget.imageWidgetsInfoNotifier.value);
  }

  Widget _buildFillPreview() {
    if (_viewportState.placementMode != PlacementMode.fill ||
        _viewportState.fillStart == null ||
        _viewportState.fillEnd == null ||
        _selectedTilePath == null) {
      return Container();
    }

    final start = _viewportState.fillStart!;
    final end = _viewportState.fillEnd!;

    final startX = min(start.dx, end.dx);
    final endX = max(start.dx, end.dx);
    final startY = min(start.dy, end.dy);
    final endY = max(start.dy, end.dy);

    final width = (endX - startX).abs() + _kDefaultObjectSize;
    final height = (endY - startY).abs() + _kDefaultObjectSize;

    if (!width.isFinite || !height.isFinite) return Container();

    return Positioned(
      left: startX,
      top: startY,
      width: width,
      height: height,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (_viewportState.placementMode == PlacementMode.fill) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition =
                renderBox.globalToLocal(details.globalPosition);
            final scenePoint = _transformationController.toScene(localPosition);

            setState(() {
              _viewportState = _viewportState.copyWith(
                fillEnd: _snapToGrid(scenePoint.dx, scenePoint.dy),
              );
            });
          }
        },
        onPanEnd: (details) {
          _handleFillEnd(_viewportState.fillEnd!);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              for (double x = 0; x <= (endX - startX); x += _kDefaultObjectSize)
                for (double y = 0;
                    y <= (endY - startY);
                    y += _kDefaultObjectSize)
                  Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: 0.5,
                      child: Image.file(
                        File(_selectedTilePath!),
                        width: _kDefaultObjectSize,
                        height: _kDefaultObjectSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSelected = false;

  Widget _buildPlayer() {
    return Positioned(
      left: _playerX,
      top: _playerY,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isSelected = true;
              _viewportState = _viewportState.copyWith(isDragging: true);
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition =
                  renderBox.globalToLocal(details.globalPosition);
              final scenePoint =
                  _transformationController.toScene(localPosition);
              _dragOffset =
                  Offset(_playerX - scenePoint.dx, _playerY - scenePoint.dy);
            });
          },
          onPanUpdate: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition =
                renderBox.globalToLocal(details.globalPosition);
            final scenePoint = _transformationController.toScene(localPosition);

            setState(() {
              _playerX = scenePoint.dx + _dragOffset.dx;
              _playerY = scenePoint.dy + _dragOffset.dy;

            GameDataManager().updatePlayer(PlayerObject(
                  path: _playerPath!,
                  x: _playerX,
                  y: _playerY,
                  speed: GameDataManager().playerState.value.speed,
                  gravity: GameDataManager().playerState.value.gravity,
                  hpManager: GameDataManager().playerState.value.hpManager));
            });
          },
          onPanEnd: (_) {
            setState(() {
              _isSelected = false;
              _viewportState = _viewportState.copyWith(isDragging: false);
              GameDataManager().updatePlayer(PlayerObject(
                  path: _playerPath!,
                  x: _playerX,
                  y: _playerY,
                  speed: GameDataManager().playerState.value.speed,
                  gravity: GameDataManager().playerState.value.gravity,
                  hpManager: GameDataManager().playerState.value.hpManager));
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: _isSelected
                  ? Border.all(color: Colors.purple, width: 2.0)
                  : null,
            ),
            child: SizedBox(
              width: _kPlayerWidth,
              height: _kPlayerHeight,
              child: _playerPath != null && File(_playerPath!).existsSync()
                  ? Image.file(File(_playerPath!))
                  : Container(),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDragAccept(DragTargetDetails<List<dynamic>> details) async {
    final item = details.data;
    // if (item.length != 2 || item[1] == 2) return;

    final imagePath =
        '${_customPathController.text}/${_projectNameController.text}${item[0]}';
    if (!File(imagePath).existsSync()) return;

    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(details.offset);
      final scenePoint = _transformationController.toScene(localPosition);
      final snappedPosition = _snapToGrid(scenePoint.dx, scenePoint.dy);

      if (_viewportState.placementMode == PlacementMode.fill) {
        _isFillingArea = true;
        setState(() {
          _selectedTilePath = imagePath;
          _viewportState = _viewportState.copyWith(
            fillStart: snappedPosition,
            fillEnd: snappedPosition,
          );
        });
        return;
      }

      final updatedList =
          List<ImageWidgetInfo>.from(widget.imageWidgetsInfoNotifier.value)
            ..add(
              ImageWidgetInfo(
                path: imagePath,
                name:
                    'Object ${widget.imageWidgetsInfoNotifier.value.length + 1}',
                x: snappedPosition.dx - (_kDefaultObjectSize / 2),
                y: snappedPosition.dy - (_kDefaultObjectSize / 2),
                width: _kDefaultObjectSize,
                height: _kDefaultObjectSize,
                collision: false,
                isEnemy: false,
                movementPath: [],
                currentPathIndex: 0,
              ),
            );

      widget.imageWidgetsInfoNotifier.value = updatedList;

      GameDataManager().saveImages(widget.imageWidgetsInfoNotifier.value);
    } catch (e) {
      debugPrint('Error in _handleDragAccept: $e');
    }
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;
  final double opacity;

  GridPainter({
    required this.gridSize,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      gridSize != oldDelegate.gridSize || opacity != oldDelegate.opacity;
}

class GroupedImageInfo extends ImageWidgetInfo {
  final List<TileInfo> tiles;
  final Size gridSize;

  GroupedImageInfo({
    required super.path,
    required super.name,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.tiles,
    required this.gridSize,
    super.collision = false,
  });
}

class TileInfo {
  final double relativeX;
  final double relativeY;

  TileInfo(this.relativeX, this.relativeY);
}

class PathPainter extends CustomPainter {
  final List<Point> points;
  final Offset? previewPoint;
  final Color color;

  PathPainter({
    required this.points,
    this.previewPoint,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty && previewPoint == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points.first.x, points.first.y);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }

      if (previewPoint != null && points.isNotEmpty) {
        path.lineTo(previewPoint!.dx, previewPoint!.dy);
      }

      canvas.drawPath(path, paint);

      for (int i = 0; i < points.length; i++) {
        canvas.drawCircle(Offset(points[i].x, points[i].y), 8, nodePaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(points[i].x - textPainter.width / 2,
              points[i].y - textPainter.height / 2),
        );
      }
    }

    if (previewPoint != null) {
      final previewPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(previewPoint!, 12, previewPaint);

      canvas.drawCircle(previewPoint!, 6, nodePaint);
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) =>
      points != oldDelegate.points ||
      previewPoint != oldDelegate.previewPoint ||
      color != oldDelegate.color;
}
