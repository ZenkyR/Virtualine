// ignore: implementation_imports
import 'package:flame/src/game/game_widget/game_widget.dart';
import 'package:flutter/material.dart';
import 'package:virtualine/base_page.dart';
import 'package:virtualine/src/game_page/game_page.dart';

class ConstructorPage extends BasePage {
  const ConstructorPage({super.key, required super.imageWidgetsInfoNotifier});

  @override
  Widget buildContent(BuildContext context) {
    return const Stack(
      
    );
  }

  @override
  GameWidget<MyGame>? createGame() {
    throw UnimplementedError();
  }
}