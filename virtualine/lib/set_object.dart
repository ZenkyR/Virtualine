// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualine/src/game_page/components/hp.dart';

class PlayerObject {
  late final String path;
  double x;
  double y;
  double speed;
  double gravity;
  final HPManager hpManager;

  PlayerObject({
    required this.path,
    required this.x,
    required this.y,
    this.speed = 1,
    this.gravity = 0,
    HPManager? hpManager,
  }) : hpManager = hpManager ?? HPManager(maxHP: 100);

  Map<String, dynamic> toMap() => {
        'path': path,
        'x': x,
        'y': y,
        'speed': speed,
        'gravity': gravity,
        'maxHP': hpManager.maxHP,
        'currentHP': hpManager.currentHP,
      };

static PlayerObject fromMap(Map<String, dynamic> map) {
   var hpManager = HPManager(maxHP: map['maxHP']);
   if (map.containsKey('currentHP') && map['currentHP'] > 0) {
      hpManager.reduceHP(hpManager.maxHP - (map['currentHP'] as int));
   }
   return PlayerObject(
      path: map['path'],
      x: map['x'].toDouble(),
      y: map['y'].toDouble(),
      speed: map['speed'].toDouble(),
      gravity: map['gravity'].toDouble(),
      hpManager: hpManager,
   );
}

}



class ImageWidgetInfo {
  final String path;
  String name;
  double x;
  double y;
  double width;
  double height;
  bool collision;
  bool finished;

  bool isEnemy;
  HPManager? enemyHPManager;
  double damage;
  List<Point> movementPath;
  int currentPathIndex;
  double movementSpeed;

  ImageWidgetInfo({
    required this.path,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.collision = false,
    this.finished = false,
    this.isEnemy = false,
    this.enemyHPManager,
    this.damage = 0,
    this.movementPath = const [],
    this.currentPathIndex = 0,
    this.movementSpeed = 1,
  }) {
    if (isEnemy && enemyHPManager == null) {
      enemyHPManager = HPManager(maxHP: 100);
    }
  }

  Map<String, dynamic> toMap() => {
        'path': path,
        'name': name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'collision': collision,
        'finished': finished,
        'isEnemy': isEnemy,
        'maxHP': enemyHPManager?.maxHP ?? 100,
        'currentHP': enemyHPManager?.currentHP ?? enemyHPManager?.maxHP,
        'damage': damage,
        'movementPath': movementPath.map((p) => p.toMap()).toList(),
        'currentPathIndex': currentPathIndex,
        'movementSpeed': movementSpeed,
      };

  static ImageWidgetInfo fromMap(Map<String, dynamic> map) {
    List<Point> path = [];
    if (map['movementPath'] != null) {
      path = (map['movementPath'] as List)
          .map((p) => Point.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    HPManager? hpManager;
    if (map['isEnemy'] == true) {
      int maxHP = (map['maxHP'] as num?)?.toInt() ?? 100;
      hpManager = HPManager(maxHP: maxHP);
      if (map.containsKey('currentHP')) {
        int currentHP = (map['currentHP'] as num?)?.toInt() ?? maxHP;
        if (currentHP < maxHP) {
          hpManager.reduceHP(maxHP - currentHP);
        }
      }
    }

    return ImageWidgetInfo(
      path: map['path'] as String,
      name: map['name'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      collision: map['collision'] as bool? ?? false,
      finished: map['finished'] as bool? ?? false,
      isEnemy: map['isEnemy'] as bool? ?? false,
      enemyHPManager: hpManager,
      damage: (map['damage'] as num?)?.toDouble() ?? 0,
      movementPath: path,
      currentPathIndex: (map['currentPathIndex'] as num?)?.toInt() ?? 0,
      movementSpeed: (map['movementSpeed'] as num?)?.toDouble() ?? 1,
    );
  }

  bool isEnemyDead() {
    return isEnemy && enemyHPManager != null && enemyHPManager!.currentHP <= 0;
  }
}
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  Map<String, dynamic> toMap() => {
    'x': x,
    'y': y,
  };

  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
      (map['x'] as num).toDouble(),
      (map['y'] as num).toDouble(),
    );
  }
}

class GameDataManager {
  static const String PLAYER_KEY_PREFIX = 'player_';
  static const String IMAGES_KEY_PREFIX = 'images_';

  static final GameDataManager _instance = GameDataManager._internal();
  factory GameDataManager() => _instance;
  GameDataManager._internal();

  final ValueNotifier<PlayerObject> playerState = ValueNotifier<PlayerObject>(
      PlayerObject(
          path: '',
          x: 200,
          y: 100,
          speed: 1,
          gravity: 0,
          hpManager: HPManager(maxHP: 100)));


  final ValueNotifier<List<ImageWidgetInfo>> imagesState =
      ValueNotifier<List<ImageWidgetInfo>>([]);
  String? projectId;

  void setProjectId(String newProjectId) {
    projectId = newProjectId;
  }

  Future<void> initialize() async {
    await _loadAllData();
    _setupAutoSave();
  }

  void _setupAutoSave() {
    playerState.addListener(_saveGameData);
    imagesState.addListener(_saveGameData);
  }

  Future<void> savePlayer(PlayerObject player) async {
    playerState.value = player;
    await _saveGameData();
  }

  Future<void> saveImages(List<ImageWidgetInfo> images) async {
    imagesState.value = images;
    await _saveGameData();
  }

  Future<void> _saveGameData() async {
    if (projectId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('$PLAYER_KEY_PREFIX$projectId',
          jsonEncode(playerState.value.toMap())),
      prefs.setString('$IMAGES_KEY_PREFIX$projectId',
          jsonEncode(imagesState.value.map((img) => img.toMap()).toList())),
    ]);
  }

  void updatePlayer(PlayerObject newPlayer) {
    playerState.value = newPlayer;
  }

  void removeImage(String name) {
    final currentImages = List<ImageWidgetInfo>.from(imagesState.value);
    final updatedImages =
        currentImages.where((img) => img.name != name).toList();

    if (currentImages.length != updatedImages.length) {
      imagesState.value = updatedImages;
    }
  }

  Future<void> _loadAllData() async {
    if (projectId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final savedPlayer = prefs.getString('$PLAYER_KEY_PREFIX$projectId');
      if (savedPlayer != null) {
        playerState.value = PlayerObject.fromMap(jsonDecode(savedPlayer));
      }

      final savedImages = prefs.getString('$IMAGES_KEY_PREFIX$projectId');
      if (savedImages != null) {
        final imagesList = jsonDecode(savedImages) as List;
        imagesState.value = imagesList
            .map((imageMap) =>
                ImageWidgetInfo.fromMap(imageMap as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> clearCurrentProjectData() async {
    if (projectId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('$PLAYER_KEY_PREFIX$projectId'),
      prefs.remove('$IMAGES_KEY_PREFIX$projectId'),
    ]);

    playerState.value = PlayerObject(
        path: '',
        x: 200,
        y: 100,
        speed: 1,
        gravity: 0,
        hpManager: HPManager(maxHP: 100));
    imagesState.value = [];
  }
}
