import 'package:flutter/material.dart';

class LeftAnimation extends StatefulWidget {
  const LeftAnimation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LeftAnimationState createState() => _LeftAnimationState();
}

class _LeftAnimationState extends State<LeftAnimation> {
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
