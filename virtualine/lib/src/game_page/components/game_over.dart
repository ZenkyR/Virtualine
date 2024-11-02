import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const GameOverOverlay({
    super.key,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GAME OVER',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRestart,
            child: const Text('Restart'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onQuit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}
