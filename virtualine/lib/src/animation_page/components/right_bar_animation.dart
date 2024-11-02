import 'package:flutter/material.dart';
import 'package:virtualine/file_explorer.dart';

class RightAnimation extends StatefulWidget {
  const RightAnimation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RightAnimationState createState() => _RightAnimationState();
}

class _RightAnimationState extends State<RightAnimation> {
  final TextEditingController _animationNameController = TextEditingController();
  final TextEditingController _frameDelayController = TextEditingController();
  bool _isAnimationSettingsExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _frameDelayController.text = "100"; 
  }

  Widget _buildFileExplorer() {
    return FileExplorer(
      initialPath: '/assets/dessin',
      fileIcon: Icons.image,
      title: 'Explorateur de fichiers',
      fileFilter: (fileName) => 
        fileName.endsWith('.png') || 
        fileName.endsWith('.jpg') || 
        fileName.endsWith('.jpeg'),
    );
  }

  Widget _buildAnimationSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isAnimationSettingsExpanded,
        onExpansionChanged: (value) => setState(() => _isAnimationSettingsExpanded = value),
        leading: const Icon(Icons.settings, color: Colors.purple),
        title: const Text(
          'Paramètres de l\'animation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTextField(
                  controller: _animationNameController,
                  label: 'Nom de l\'animation',
                  icon: Icons.label,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _frameDelayController,
                  label: 'Délai entre les images (ms)',
                  isNumeric: true,
                  icon: Icons.timer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumeric = false,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null ? Icon(icon, color: Colors.purple) : null,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
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
            _buildFileExplorer(),
            _buildAnimationSettings(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationNameController.dispose();
    _frameDelayController.dispose();
    super.dispose();
  }
}