import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import '../../../set_stats.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  HSVColor color = HSVColor.fromColor(Colors.black);

  void onChanged(HSVColor value) {
    setState(() {
      color = value;
      colorState.value = value.toColor().value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          child: WheelPicker(
            color: color,
            onChanged: onChanged,
          ),
        ),
        HSVPicker(
          color: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
