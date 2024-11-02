import 'package:flutter/material.dart';

class LeftSound extends StatefulWidget {
  const LeftSound({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LeftSoundState createState() => _LeftSoundState();
}

class _LeftSoundState extends State<LeftSound> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        shape: BoxShape.rectangle,
      ),
    );
  }
}
