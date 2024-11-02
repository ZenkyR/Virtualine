import 'package:flutter/material.dart';

class PauseMenuOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const PauseMenuOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PAUSE',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onResume,
            child: const Text('Resume'),
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
