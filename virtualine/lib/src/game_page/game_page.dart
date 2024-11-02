import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:virtualine/set_object.dart';
import 'package:virtualine/src/game_page/components/collision.dart';
import 'package:virtualine/src/game_page/components/enemy.dart';
import 'package:virtualine/src/game_page/components/game_over.dart';
import 'package:virtualine/src/game_page/components/hp.dart';
import 'package:virtualine/src/game_page/components/main_menu.dart';
import 'package:virtualine/src/game_page/components/pause_menu.dart';
import 'package:virtualine/src/game_page/components/player.dart';
import 'package:virtualine/base_page.dart';
import 'package:virtualine/src/game_page/components/victory.dart';

class GamePage extends BasePage {
  const GamePage({
    super.key,
    required super.imageWidgetsInfoNotifier,
    super.disableZoom = true,
  }) : super(isGameMode: true);

  @override
  GameWidget<MyGame> createGame() {
    var game = MyGame(imageWidgetsInfo: imageWidgetsInfoNotifier.value);

    game.pauseEngine();

    return GameWidget(
      game: game,
      overlayBuilderMap: {
        'PauseMenu': (BuildContext context, MyGame game) {
          return PauseMenuOverlay(
            onResume: () => game.togglePauseMenu(),
            onQuit: () => Navigator.of(context).pop(),
          );
        },
        'GameOver': (BuildContext context, MyGame game) {
          return GameOverOverlay(
            onRestart: () {
              game.overlays.remove('GameOver');
              game.resumeEngine();
              game.player.reset();
              for (var enemy in game.enemies) {
                enemy.reset();
              }
            },
            onQuit: () => Navigator.of(context).pop(),
          );
        },
        'Victory': (BuildContext context, MyGame game) {
          return VictoryOverlay(
            onRestart: () {
              game.overlays.remove('Victory');
              game.resumeEngine();
              game.player.reset();
              for (var enemy in game.enemies) {
                enemy.reset();
              }
            },
            onQuit: () => Navigator.of(context).pop(),
          );
        },
        'StartMenu': (BuildContext context, MyGame game) {
          return StartMenuOverlay(
            onStart: () {
              game.overlays.remove('StartMenu');
              game.resumeEngine();
            },
            onQuit: () => Navigator.of(context).pop(),
          );
        },
      },
      initialActiveOverlays: const ['StartMenu'],
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    throw UnimplementedError();
  }
}

class MyGame extends FlameGame
    with KeyboardEvents, HasCollisionDetection, TapDetector {
  final List<ImageWidgetInfo> imageWidgetsInfo;
  final List<Enemy> enemies = [];

  late Player player;
  late CameraComponent cameraComponent;
  bool isPaused = false;

  MyGame({required this.imageWidgetsInfo});

  final Set<LogicalKeyboardKey> _movementKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyZ,
    LogicalKeyboardKey.keyQ,
  };

  @override
  Future<void> onLoad() async {
    player = Player(this)
      ..position = Vector2(
        GameDataManager().playerState.value.x,
        GameDataManager().playerState.value.y,
      );

    final world = World();

    for (var info in imageWidgetsInfo) {
      if (info.isEnemy) {
        final enemy = await Enemy.create(
          imagePath: info.path,
          position: Vector2(info.x, info.y),
          size: Vector2(info.width, info.height),
          movementPath: info.movementPath,
          movementSpeed: info.movementSpeed,
          damage: info.damage,
          hpManager: info.enemyHPManager ?? HPManager(maxHP: 100),
        );
        enemies.add(enemy);
        world.add(enemy);
      } else {
        final gameObject = await createGameObject(
          position: Vector2(info.x, info.y),
          size: Vector2(info.width, info.height),
          imagePath: info.path,
          hasCollision: info.collision,
          finished: info.finished,
        );
        world.add(gameObject);
      }
    }

    world.add(player);

    cameraComponent = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.center;

    cameraComponent.follow(player);
    addAll([world, cameraComponent]);

    //debugMode = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    List<Enemy> enemiesToRemove = [];
    for (var enemy in enemies) {
      enemy.update(dt);

      if (enemy.isDead) {
        enemy.removeFromParent();
        enemiesToRemove.add(enemy);
      }
    }

    enemies.removeWhere((enemy) => enemiesToRemove.contains(enemy));

     if (player.isDead) {
       overlays.add('GameOver');
       pauseEngine();
     }
  }

  void handlePlayerMovement(Set<LogicalKeyboardKey> keysPressed) {
    bool up = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.keyZ);
    bool down = keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS);
    bool left = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.keyQ);
    bool right = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);

    if (up && left) {
      player.moveUpLeft();
    } else if (up && right) {
      player.moveUpRight();
    } else if (down && left) {
      player.moveDownLeft();
    } else if (down && right) {
      player.moveDownRight();
    } else {
      if (up) {
        player.moveUp();
      } else if (down) {
        player.moveDown();
      }
      if (left) {
        player.moveLeft();
      } else if (right) {
        player.moveRight();
      }
    }
  }

  void togglePauseMenu() {
    isPaused = !isPaused;
    if (isPaused) {
      overlays.add('PauseMenu');
      pauseEngine();
    } else {
      overlays.remove('PauseMenu');
      resumeEngine();
    }
  }

  void handleKeyDown(Set<LogicalKeyboardKey> keysPressed) {
    handlePlayerMovement(keysPressed);
  }

  void handleKeyUp(Set<LogicalKeyboardKey> keysPressed) {
    if (_movementKeys.intersection(keysPressed).isEmpty) {
      player.stop();
    } else {
      handlePlayerMovement(keysPressed);
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      togglePauseMenu();
      return KeyEventResult.handled;
    }

    if (!isPaused) {
      if (event is KeyDownEvent) {
        handleKeyDown(keysPressed);
      } else if (event is KeyUpEvent) {
        handleKeyUp(keysPressed);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
