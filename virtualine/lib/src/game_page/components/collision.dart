import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class GameObject extends PositionComponent with CollisionCallbacks {
  bool canJumpThrough;
  bool finished;
  late RectangleHitbox hitbox;
  late SpriteComponent sprite;

  GameObject({
    required Vector2 position,
    required Vector2 size,
    required this.sprite,  
    required bool hasCollision,
    required this.finished,
    this.canJumpThrough = false,
  }) : super(position: position, size: size) {
    add(sprite);
    hitbox = RectangleHitbox(); 
    if (hasCollision) {
      hitbox = RectangleHitbox();
      add(hitbox);
    }

    if (finished) {
    }
  }
}

Future<GameObject> createGameObject({
  required Vector2 position,
  required Vector2 size,
  required String imagePath,
  required bool hasCollision,
  required bool finished, 

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
  final sprite = SpriteComponent.fromImage(image)
    ..size = size;  

  return GameObject(
    position: position,
    size: size,
    sprite: sprite,  
    hasCollision: hasCollision,
    finished: finished,
  );
}
