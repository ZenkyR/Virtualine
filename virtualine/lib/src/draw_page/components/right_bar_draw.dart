import 'package:flutter/material.dart';
import 'color_picker.dart';
import '../../../set_stats.dart';

class RightDrawer extends StatefulWidget {
  const RightDrawer({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RightDrawerState createState() => _RightDrawerState();
}

class _RightDrawerState extends State<RightDrawer> {
  bool _isColorPickerExpanded = true;
  bool _isBrushSettingsExpanded = true;

  Widget _buildColorPickerSection() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isColorPickerExpanded,
        onExpansionChanged: (value) => setState(() => _isColorPickerExpanded = value),
        leading: const Icon(Icons.palette, color: Colors.purple),
        title: const Text(
          'Sélecteur de couleur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ColorPicker(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isBrushSettingsExpanded,
        onExpansionChanged: (value) => setState(() => _isBrushSettingsExpanded = value),
        leading: const Icon(Icons.brush, color: Colors.purple),
        title: const Text(
          'Paramètres du pinceau',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSliderSection(
                  label: 'Épaisseur',
                  value: widthState.value,
                  min: 1.0,
                  max: 200.0,
                  onChanged: (value) {
                    setState(() {
                      widthState.value = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildSliderSection(
                  label: 'Opacité',
                  value: opacityState.value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      opacityState.value = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.purple,
            thumbColor: Colors.purple,
            overlayColor: Colors.purple.withOpacity(0.2),
            inactiveTrackColor: Colors.grey[700],
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildColorPickerSection(),
            _buildBrushSettings(),
          ],
        ),
      ),
    );
  }
}