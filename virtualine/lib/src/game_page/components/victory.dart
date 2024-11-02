import 'package:flutter/material.dart';

class VictoryOverlay extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const VictoryOverlay({
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
            'YOU WIN!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRestart,
            child: const Text('Play Again'),
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
