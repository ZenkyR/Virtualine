import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:virtualine/search_directory.dart';
import 'package:virtualine/set_object.dart';
import 'components/page.dart';
import '../../../set_stats.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  List<String> _projects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => _isLoading = true);
    await loadPathProject(_pathController, _listDirectories);
    setState(() => _isLoading = false);
  }

  void _listDirectories(String pathString) {
    setState(() {
      _projects = listDirectories(pathString);
    });
  }

  Future<void> _chooseDirectory() async {
    await chooseDirectory(_pathController, _listDirectories);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          backgroundColor: Colors.grey[900],
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          actions: [
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.purple),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createProject() async {
    if (_pathController.text.isEmpty) {
      _showErrorDialog('Erreur', 'Veuillez choisir un chemin pour le projet');
      return;
    }

    if (_projectNameController.text.isEmpty) {
      _showErrorDialog('Erreur', 'Veuillez entrer un nom pour le projet');
      return;
    }

    final String projectPath = _pathController.text;
    final String projectName = _projectNameController.text;
    final String newProjectPath = path.join(projectPath, projectName);

    if (Directory(newProjectPath).existsSync()) {
      _showErrorDialog('Erreur', 'Un projet avec ce nom existe déjà');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _createProjectStructure(newProjectPath);
      _listDirectories(_pathController.text);
      _projectNameController.clear();
    } catch (e) {
      _showErrorDialog('Erreur', 'Erreur lors de la création du projet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createProjectStructure(String projectPath) async {
    final directories = [
      path.join(projectPath, 'assets', 'dessin'),
      path.join(projectPath, 'assets', 'animation'),
      path.join(projectPath, 'assets', 'sons'),
    ];

    for (final dir in directories) {
      await Directory(dir).create(recursive: true);
    }
  }

Future<void> _openProject(String projectName) async {
  GameDataManager().setProjectId(projectName);
  navIndex.value = 0;

  setState(() => _isLoading = true);
  await GameDataManager().initialize();
  setState(() => _isLoading = false);

  savePathProject(_pathController.text);
  _projectNameController.text = projectName;
  saveProjectName(_projectNameController);

  if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyHomePage(title: 'Virtualine'),
      ),
    );
  }
}



  Widget _buildProjectCard(String projectName) {
    return Card(
      color: Colors.grey[850],
      elevation: 4,
      child: InkWell(
        onTap: () => _openProject(projectName),
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.purple.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder,
                size: 64,
                color: Colors.purple.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                projectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Text(
          'Aucun projet trouvé\nCréez un nouveau projet pour commencer',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) => _buildProjectCard(_projects[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Virtualine - Projets',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[850],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Emplacement des projets',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.folder_open, color: Colors.purple),
                        onPressed: _chooseDirectory,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                    readOnly: true,
                    onTap: _chooseDirectory,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _projectNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nouveau projet',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: Colors.purple),
                        onPressed: _createProject,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                    onSubmitted: (_) => _createProject(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildProjectGrid(),
          ),
        ],
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
