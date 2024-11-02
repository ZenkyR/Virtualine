import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:virtualine/set_object.dart';
import 'package:virtualine/src/game_page/components/hp.dart';
import 'package:virtualine/src/game_page/components/player.dart';
import 'dart:math';

class Enemy extends SpriteComponent with CollisionCallbacks {
  final List<Point> movementPath;
  final double movementSpeed;
  int currentPathIndex = 0;
  final double damage;
  final HPManager hpManager;

  bool get isDead => hpManager.currentHP <= 0;

  Enemy._({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    required this.movementPath,
    required this.movementSpeed,
    required this.damage,
    required this.hpManager,
  }) : super(sprite: sprite, position: position, size: size) {
    add(RectangleHitbox());
  }

  static Future<Enemy> create({
    required String imagePath,
    required Vector2 position,
    required Vector2 size,
    required List<Point> movementPath,
    required double movementSpeed,
    required double damage,
    required HPManager hpManager,
  }) async {
    final Map<String, ui.Image> cache = {};

    if (!cache.containsKey(imagePath)) {
      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      cache[imagePath] = frame.image;
    }

    final image = cache[imagePath]!;
    final spriteComponent = SpriteComponent.fromImage(image)..size = size;
    final sprite = spriteComponent.sprite!;

    return Enemy._(
      sprite: sprite,
      position: position,
      size: size,
      movementPath: movementPath,
      movementSpeed: movementSpeed,
      damage: damage,
      hpManager: hpManager,
    );
  }

  @override
  void update(double dt) {
    if (isDead) return;

    super.update(dt);
    if (movementPath.isEmpty) return;

    var targetPoint = movementPath[currentPathIndex];
    var targetX = targetPoint.x - size.x / 2;
    var targetY = targetPoint.y - size.y / 2;
    var dx = targetX - position.x;
    var dy = targetY - position.y;
    var distance = sqrt(dx * dx + dy * dy);

    if (distance <= movementSpeed) {
      position.x = targetX;
      position.y = targetY;
      currentPathIndex = (currentPathIndex + 1) % movementPath.length;
    } else {
      var ratio = movementSpeed / distance;
      position.x += dx * ratio;
      position.y += dy * ratio;
    }
  }

  void takeDamage(double amount) {
    hpManager.reduceHP(amount.toInt());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (!isDead && other is Player) {
      other.takeDamage(damage.toInt());
    }
  }

  void reset() {
    position = movementPath.isNotEmpty
        ? Vector2(
            movementPath[0].x - size.x / 2, movementPath[0].y - size.y / 2)
        : Vector2.zero();

    currentPathIndex = 0;
    hpManager.resetHP();
  }
}
