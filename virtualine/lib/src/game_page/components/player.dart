import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:virtualine/set_object.dart';
import 'package:virtualine/src/game_page/components/collision.dart';
import 'package:flame/game.dart';

class Player extends SpriteAnimationComponent with CollisionCallbacks {
  final FlameGame gameRef;
  Offset velocity = Offset.zero;
  double speed = GameDataManager().playerState.value.speed * 100;
  double gravity = GameDataManager().playerState.value.gravity;
  bool isOnGround = false;

  late Size screenSize =
      ui.PlatformDispatcher.instance.views.first.physicalSize /
          ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
  late RectangleHitbox hitbox;

  RectangleComponent? hpBarBorder;
  RectangleComponent? hpBarFill;
  late StreamSubscription<int> _hpSubscription;

  Player(this.gameRef) : super(size: Vector2(120, 120));

  static final Map<String, ui.Image> _cache = {};

  int currentHP = GameDataManager().playerState.value.hpManager.maxHP;

  bool get isDead => currentHP <= 0;

  @override
  Future<void> onLoad() async {
    GameDataManager().playerState.value.hpManager.setCurrentHP(currentHP);
    hitbox = RectangleHitbox();
    final path = GameDataManager().playerState.value.path;

    if (!File(path).existsSync()) {
      debugPrint('Le fichier sprite n\'existe pas: $path');
      return;
    }

    ui.Image image;
    if (_cache.containsKey(path)) {
      image = _cache[path]!;
    } else {
      final file = File(path);
      final imageBytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      _cache[path] = image;
    }

    if (isSpriteSheet(path)) {
      final spriteSheet = SpriteSheet(
        image: image,
        srcSize: Vector2(64, 64),
      );
      animation = spriteSheet.createAnimation(
        row: 0,
        stepTime: 0.5,
        from: 0,
      );
    } else {
      final sprite = Sprite(image);
      animation = SpriteAnimation.spriteList(
        [sprite],
        stepTime: 1,
      );
    }

    _setupHealthBar();

    add(hitbox);
  }

  void _setupHealthBar() {
    _hpSubscription =
        GameDataManager().playerState.value.hpManager.hpStream.listen((hp) {
      if (hpBarFill != null) {
        currentHP = hp; 
        double hpPercentage =
            hp / GameDataManager().playerState.value.hpManager.maxHP;
        hpBarFill!.size.x = 96 * hpPercentage;
        hpBarFill!.paint.color =
            Color.lerp(Colors.red, Colors.greenAccent, hpPercentage)!;
      }
    });

    hpBarBorder = RectangleComponent(
      size: Vector2(100, 20),
      paint: Paint()..color = Colors.black,
      position: Vector2(size.x / 2 - 50, -35),
    );
    add(hpBarBorder!);

    hpBarFill = RectangleComponent(
      size: Vector2(96, 18),
      paint: Paint()..color = Colors.greenAccent,
      position: Vector2(size.x / 2 - 48, -33),
    );
    add(hpBarFill!);
  }

  bool isSpriteSheet(String path) {
    return path.endsWith('_sheet.png') || path.contains('spritesheet');
  }

  @override
  void onRemove() {
    _hpSubscription.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isOnGround) {
      velocity = velocity + Offset(0, gravity * dt);
    }

    double newX = x + velocity.dx * speed * dt;
    double newY = y + velocity.dy * speed * dt;

    final playerRect = hitbox.toAbsoluteRect();
    final newRect = playerRect.translate(
        velocity.dx * speed * dt, velocity.dy * speed * dt);
    bool collision = false;

    parent?.children.whereType<GameObject>().forEach((component) {
      if (component.hitbox.isMounted) {
        final objectRect = component.hitbox.toAbsoluteRect();
        if (newRect.overlaps(objectRect)) {
          collision = true;
          debugPrint('Collision détectée avec un GameObject !');

          if (component.finished) {
            gameRef.overlays.add('Victory');
            gameRef.pauseEngine();
          }

          if (velocity.dy > 0) {
            isOnGround = true;
            velocity = Offset(velocity.dx, 0);
          }
        }
      }
    });

    parent?.children.whereType<GameObject>().forEach((component) {
      if (!component.hitbox.isMounted && component.finished) {
        final objectRect = Rect.fromLTWH(
          component.position.x,
          component.position.y,
          component.size.x,
          component.size.y,
        );

        if (newRect.overlaps(objectRect)) {
          gameRef.overlays.add('Victory');
          gameRef.pauseEngine();
        }
      }
    });

    if (!collision) {
      isOnGround = false;
      x = newX;
      y = newY;
    }
  }

  void setDirection(Offset direction) {
    velocity = direction;

    if (direction.dy < 0) {
      isOnGround = false;
    }
  }

  void moveUp() => setDirection(const Offset(0, -1));
  void moveDown() => setDirection(const Offset(0, 1));
  void moveLeft() => setDirection(const Offset(-1, 0));
  void moveRight() => setDirection(const Offset(1, 0));
  void moveUpLeft() => setDirection(const Offset(-1, -1));
  void moveUpRight() => setDirection(const Offset(1, -1));
  void moveDownLeft() => setDirection(const Offset(-1, 1));
  void moveDownRight() => setDirection(const Offset(1, 1));
  void stop() => setDirection(Offset.zero);

  void reset() {
    x = GameDataManager().playerState.value.x;
    y = GameDataManager().playerState.value.y;
    velocity = Offset.zero;
    currentHP = GameDataManager().playerState.value.hpManager.maxHP;
    GameDataManager().playerState.value.hpManager.setCurrentHP(currentHP);
  }

  void takeDamage(int int) {
    currentHP = currentHP - int;
    GameDataManager().playerState.value.hpManager.reduceHP(int);
  }
}
