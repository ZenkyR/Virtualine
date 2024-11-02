import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:virtualine/file_explorer.dart';
import 'package:virtualine/search_directory.dart';
import 'package:virtualine/set_stats.dart';

class RightSound extends StatefulWidget {
  const RightSound({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RightSoundState createState() => _RightSoundState();
}

class _RightSoundState extends State<RightSound> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  bool _isSoundSettingsExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    loadProjectName(_projectNameController);
    loadPathProject(_pathController, __listDirectories);
  }

  void __listDirectories(String pathString) {}

  Future<void> _pickAndImportMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      String dir = '${_pathController.text}/${_projectNameController.text}/assets/sons';
      final String filePath = result.files.single.path!;
      final File originalFile = File(filePath);
      final String fileName = basename(filePath);
      final String newPath = '$dir/$fileName';
      await originalFile.copy(newPath);

      setState(() {});
    }
  }

  Widget _buildFileExplorer() {
    return FileExplorer(
      initialPath: '/assets/sons',
      folderIcon: Icons.library_music,
      fileIcon: Icons.audiotrack,
      title: 'Explorateur de sons',
      onFileTap: (item) => selectedSound(item[0]),
    );
  }

  void selectedSound(String sound) {
    projectPathSound.value = sound;
  }

  Widget _buildSoundSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isSoundSettingsExpanded,
        onExpansionChanged: (value) => setState(() => _isSoundSettingsExpanded = value),
        leading: const Icon(Icons.settings, color: Colors.purple),
        title: const Text(
          'Paramètres audio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndImportMusic,
                  icon: const Icon(Icons.add, color: Colors.purple),
                  label: const Text('Importer une musique'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            _buildSoundSettings(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }
}