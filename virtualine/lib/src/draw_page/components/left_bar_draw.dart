import 'package:flutter/material.dart';
import '../../../set_stats.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LeftDrawer extends StatefulWidget {
  const LeftDrawer({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LeftDrawerState createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> {
  int _selectedButton = 0;

  final List<DrawerTool> _tools = [
    DrawerTool(
      index: 0,
      icon: Icons.create_outlined,
      tooltip: 'Crayon',
      onSelect: () {
        eraserState.value = false;
        fullPaintState.value = false;
      },
    ),
    DrawerTool(
      index: 1,
      icon: FontAwesomeIcons.eraser,
      tooltip: 'Gomme',
      onSelect: () {
        eraserState.value = true;
        opacityState.value = 1.0;
        fullPaintState.value = false;
      },
    ),
    DrawerTool(
      index: 2,
      icon: Icons.format_color_fill_outlined,
      tooltip: 'Remplissage',
      onSelect: () {
        fullPaintState.value = true;
      },
    ),
    DrawerTool(
      index: 3,
      icon: Icons.colorize_outlined,
      tooltip: 'Pipette',
      onSelect: () {
        pipetteState.value = true;
        fullPaintState.value = false;
      },
    ),
  ];

  Widget _buildToolButton(DrawerTool tool) {
    return Material(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: _selectedButton == tool.index 
          ? Colors.purple.shade700 
          : Colors.transparent,
      child: IconButton(
        icon: Icon(tool.icon),
        onPressed: () {
          setState(() {
            _selectedButton = tool.index;
            tool.onSelect();
          });
        },
        color: Colors.white,
        hoverColor: Colors.purple.shade700,
        tooltip: tool.tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        shape: BoxShape.rectangle,
      ),
      child: Column(
        children: _tools.map(_buildToolButton).toList(),
      ),
    );
  }
}

class DrawerTool {
  final int index;
  final IconData icon;
  final String tooltip;
  final VoidCallback onSelect;

  DrawerTool({
    required this.index,
    required this.icon,
    required this.tooltip,
    required this.onSelect,
  });
}