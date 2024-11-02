import 'package:flutter/material.dart';

class StartMenuOverlay extends StatelessWidget {
  final VoidCallback onStart;
    final VoidCallback onQuit;


  const StartMenuOverlay({
    super.key,
    required this.onStart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GAME TITLE',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onStart,
            child: const Text('Start Game'),
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
