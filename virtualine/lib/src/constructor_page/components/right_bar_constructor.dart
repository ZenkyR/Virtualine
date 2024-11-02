import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:virtualine/file_explorer.dart';
import 'package:virtualine/search_directory.dart';
import 'package:virtualine/set_object.dart';

class RightConstructor extends StatefulWidget {
  const RightConstructor({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RightConstructorState createState() => _RightConstructorState();
}

class _RightConstructorState extends State<RightConstructor> {
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerXController = TextEditingController();
  final TextEditingController _playerYController = TextEditingController();
  final TextEditingController _playerSpeedController = TextEditingController();
  final TextEditingController _playerGravityController =
      TextEditingController();
  final TextEditingController _playerHPController = TextEditingController();
  bool _isPlayerSettingsExpanded = true;
  TextEditingController pathController = TextEditingController();
  TextEditingController projectNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    GameDataManager().playerState.addListener(() {
      if (mounted) {
        setState(() {
          _updatePlayerControllers();
        });
      }
    });
  }

  void _initializeControllers() {
    loadPathProject(pathController, __listDirectories);
    loadProjectName(projectNameController);
    _updatePlayerControllers();
  }

  void __listDirectories(String pathString) {}

  void _updatePlayerControllers() {
    _playerNameController.text = GameDataManager().playerState.value.path;
    _playerXController.text =
        GameDataManager().playerState.value.x.toStringAsFixed(2);
    _playerYController.text =
        GameDataManager().playerState.value.y.toStringAsFixed(2);
    _playerSpeedController.text =
        GameDataManager().playerState.value.speed.toString();
    _playerGravityController.text =
        GameDataManager().playerState.value.gravity.toString();
    _playerHPController.text =
        GameDataManager().playerState.value.hpManager.maxHP.toString();
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

  Widget _buildFileAnimationExplorer() {
    return FileExplorer(
      initialPath: '/assets/animation',
      fileIcon: Icons.movie,
      title: 'Explorateur d\'animations',
      fileFilter: (fileName) =>
          fileName.endsWith('.gif') ||
          fileName.endsWith('.webp') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg'),
    );
  }

  Future<void> _selectPlayerImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      final file = result.files.first;
      final manager = GameDataManager();
      final currentPlayer = manager.playerState.value;
      manager.updatePlayer(
        PlayerObject(
          path: file.path!,
          x: currentPlayer.x,
          y: currentPlayer.y,
          speed: currentPlayer.speed,
          gravity: currentPlayer.gravity,
          hpManager: currentPlayer.hpManager,
        ),
      );
      _playerNameController.text = file.name;
      await manager.savePlayer(manager.playerState.value);
    }
  }

  Widget _buildPlayerSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isPlayerSettingsExpanded,
        onExpansionChanged: (value) =>
            setState(() => _isPlayerSettingsExpanded = value),
        leading: const Icon(Icons.sports_esports, color: Colors.purple),
        title: const Text(
          'Paramètres du joueur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DragTarget<List<dynamic>>(
                  onAcceptWithDetails: (details) async {
                    debugPrint('Accepté: ${details.data}');
                    final fileName = details.data[0] as String;
                    
                    final fullPath = '${pathController.text}/${projectNameController.text}$fileName';

                    final manager = GameDataManager();
                    final currentPlayer = manager.playerState.value;
                    manager.updatePlayer(
                      PlayerObject(
                        path: fullPath,
                        x: currentPlayer.x,
                        y: currentPlayer.y,
                        speed: currentPlayer.speed,
                        gravity: currentPlayer.gravity,
                        hpManager: currentPlayer.hpManager,
                      ),
                    );
                    _playerNameController.text = fullPath;
                    await manager.savePlayer(manager.playerState.value);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return _buildTextField(
                      controller: _playerNameController,
                      label: 'Sprite du joueur',
                      onTap: _selectPlayerImage,
                      onChanged: (value) {
                        final manager = GameDataManager();
                        final currentPlayer = manager.playerState.value;
                        manager.updatePlayer(
                          PlayerObject(
                            path: value,
                            x: currentPlayer.x,
                            y: currentPlayer.y,
                            speed: currentPlayer.speed,
                            gravity: currentPlayer.gravity,
                            hpManager: currentPlayer.hpManager,
                          ),
                        );
                      },
                      icon: Icons.image,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _playerXController,
                        label: 'Position X',
                        isNumeric: true,
                        onChanged: (value) {
                          _updatePlayerPosition('x', value);
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildTextField(
                        controller: _playerYController,
                        label: 'Position Y',
                        isNumeric: true,
                        onChanged: (value) {
                          _updatePlayerPosition('y', value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _playerSpeedController,
                  label: 'Vitesse',
                  isNumeric: true,
                  onChanged: (value) {
                    GameDataManager().playerState.value.speed =
                        value.isEmpty ? 0.0 : double.parse(value);
                    GameDataManager()
                        .savePlayer(GameDataManager().playerState.value);
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _playerGravityController,
                  label: 'Gravité',
                  isNumeric: true,
                  onChanged: (value) {
                    GameDataManager().playerState.value.gravity =
                        value.isEmpty ? 0.0 : double.parse(value);
                    GameDataManager()
                        .savePlayer(GameDataManager().playerState.value);
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _playerHPController,
                  label: 'Points de Vie (HP)',
                  isNumeric: true,
                  onChanged: (value) {
                    int newHP = value.isEmpty ? 0 : int.parse(value);
                    GameDataManager().playerState.value.hpManager.maxHP = newHP;
                    GameDataManager()
                        .savePlayer(GameDataManager().playerState.value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updatePlayerPosition(String axis, String value) {
    if (value.isEmpty) return;

    try {
      final doubleValue = double.parse(value);

      setState(() {
        if (axis == 'x') {
          GameDataManager().playerState.value.x = doubleValue;
        } else {
          GameDataManager().playerState.value.y = doubleValue;
        }

        GameDataManager().savePlayer(GameDataManager().playerState.value);
      });
    } catch (e) {
      debugPrint('Erreur de conversion: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumeric = false,
    VoidCallback? onTap,
    void Function(String)? onChanged,
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
      onTap: onTap,
      onChanged: onChanged,
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
            _buildFileAnimationExplorer(),
            _buildPlayerSettings(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _playerXController.dispose();
    _playerYController.dispose();
    _playerSpeedController.dispose();
    _playerGravityController.dispose();
    _playerHPController.dispose();
    super.dispose();
  }
}
