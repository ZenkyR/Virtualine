import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:virtualine/search_directory.dart';

class AnimationPage extends StatefulWidget {
  const AnimationPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AnimationPageState createState() => _AnimationPageState();
}

final TextEditingController _textEditingController = TextEditingController();
double _animationSpeed = 1;
int _currentAnimationIndex = 0;

class _AnimationPageState extends State<AnimationPage> {
  bool _isAnimationRunning = false;
  int _gridRowCount = 1;
  TextEditingController customPathController = TextEditingController();
  TextEditingController projectNameController = TextEditingController();
  TextEditingController nameProjetController = TextEditingController();
  List<String> directoryList = [];
  List<String> droppedImages = [];
  String spriteSheetName = '';
  int spriteWidth = 64;
  int spriteHeight = 64;

  final Map<int, XFile?> _selectedImages = {};
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    loadPathProject(customPathController, _listDirectories);
    loadProjectName(projectNameController);
  }

  void _listDirectories(String pathString) {
    setState(() {
      directoryList = listDirectories(pathString);
    });
  }

  void toggleAnimation() {
    setState(() {
      if (_selectedImages.isEmpty) {
        return;
      }
      _isAnimationRunning = !_isAnimationRunning;
      if (_isAnimationRunning) {
        startAnimation();
      } else {
        stopAnimation();
      }
    });
  }

  void startAnimation() {
    _animationTimer = Timer.periodic(
        Duration(milliseconds: (_animationSpeed).toInt()), (timer) {
      if (mounted) {
        setState(() {
          if (_selectedImages.isNotEmpty) {
            _currentAnimationIndex =
                (_currentAnimationIndex + 1) % _selectedImages.length;
          }
        });
      }
    });
  }

  void stopAnimation() {
    _animationTimer?.cancel();
  }

  void setSpeed(double speed) {
    setState(() {
      _animationSpeed = speed;
      if (_isAnimationRunning) {
        _animationTimer?.cancel();
        startAnimation();
      }
    });
  }

  void selectPlayerImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _gridRowCount++;
        _selectedImages[_gridRowCount - 2] = XFile(result.files.single.path!);
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      _selectedImages.remove(index);
      _gridRowCount--;

      List<int> keys = _selectedImages.keys.toList();
      for (int key in keys) {
        if (key > index) {
          _selectedImages[key - 1] = _selectedImages[key];
          _selectedImages.remove(key);
        }
      }
    });
  }

  void moveImage(int fromIndex, int toIndex) {
    setState(() {
      if (_selectedImages.containsKey(fromIndex) &&
          _selectedImages.containsKey(toIndex)) {
        final temp = _selectedImages[fromIndex];
        _selectedImages[fromIndex] = _selectedImages[toIndex];
        _selectedImages[toIndex] = temp;
      }
    });
  }

  Future<void> createAndSaveSpriteSheet() async {
    if (_selectedImages.isEmpty) {
      debugPrint('Aucune image sélectionnée pour créer le sprite sheet.');
      return;
    }

    int frameCount = _selectedImages.length;

    int columns = (frameCount <= 10) ? frameCount : 10;
    int rows = (frameCount / 10).ceil();
    int spriteSheetWidth = columns * spriteWidth;
    int spriteSheetHeight = rows * spriteHeight;

    final recorder = PictureRecorder();
    final canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0, 0),
            Offset(spriteSheetWidth.toDouble(), spriteSheetHeight.toDouble())));
    final paint = Paint();

    for (var entry in _selectedImages.entries) {
      if (entry.value != null) {
        final imageFile = File(entry.value!.path);
        final bytes = await imageFile.readAsBytes();
        final codec = await instantiateImageCodec(bytes);
        final frameInfo = await codec.getNextFrame();
        final image = frameInfo.image;

        int x = (entry.key % columns) * spriteWidth;
        int y = (entry.key ~/ columns) * spriteHeight;

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(x.toDouble(), y.toDouble(), spriteWidth.toDouble(),
              spriteHeight.toDouble()),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(spriteSheetWidth, spriteSheetHeight);
    final byteData = await img.toByteData(format: ImageByteFormat.png);

    final buffer = byteData!.buffer.asUint8List();

    String dir =
        '${customPathController.text}/${projectNameController.text}/assets/animation';
    String fullPath = '$dir/$spriteSheetName' '_sheet.png';

    if (File(fullPath).existsSync()) {
      _showErrorDialog('Erreur', 'Une animation avec ce nom existe déjà');
      return;
    }

    final spriteSheetFile = File(fullPath);
    await spriteSheetFile.writeAsBytes(buffer);

    debugPrint('Sprite sheet enregistré à l\'emplacement : $fullPath');
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                nameProject();
              },
            ),
          ],
        );
      },
    );
  }

  void nameProject() {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Comment voulez-vous nommer votre animation ?'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameProjetController,
              decoration: const InputDecoration(hintText: "Nom de l'animation"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez entrer un nom pour l'animation";
                }
                return null;
              },
              onFieldSubmitted: (value) {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    spriteSheetName = nameProjetController.text;
                    Navigator.of(context).pop();
                  });
                  createAndSaveSpriteSheet();
                }
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Valider'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    spriteSheetName = nameProjetController.text;
                    Navigator.of(context).pop();
                  });
                  createAndSaveSpriteSheet();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void addDroppedImage(String path) {
    setState(() {
      _gridRowCount++;
      _selectedImages[_gridRowCount - 2] = XFile(path);
    });
  }

   @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildControlPanel(),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grille à gauche
                      Expanded(
                        flex: 3,
                        child: _buildFrameGrid(),
                      ),
                      const SizedBox(width: 24),
                      // Prévisualisation à droite
                      Expanded(
                        flex: 2,
                        child: _buildPreviewSection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.purple,
          onPressed: selectPlayerImage,
          icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
          label: const Text('Ajouter une image',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }
  
    Widget _buildHeader() {
      return const Text(
        'Éditeur d\'Animation',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  
    Widget _buildControlPanel() {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D3D3D)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpeedControl(),
            const SizedBox(height: 20),
            _buildSizeControl(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      );
    }
  
    Widget _buildSpeedControl() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vitesse d\'animation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.purple),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Slider(
                  value: _animationSpeed,
                  min: 1,
                  max: 10000,
                  activeColor: Colors.purple,
                  inactiveColor: const Color(0xFF4D4D4D),
                  onChanged: (value) {
                    setSpeed(value);
                    _textEditingController.text = value.round().toString();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _textEditingController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF3D3D3D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixText: 'ms',
                    suffixStyle: const TextStyle(color: Colors.grey),
                  ),
                  onChanged: (String value) {
                    value = value.isEmpty ? '1' : value;
                    double milliseconds = double.tryParse(value) ?? 1.0;
                    milliseconds = milliseconds.clamp(1, 10000);
                    setSpeed(milliseconds);
                    _textEditingController.text = milliseconds.round().toString();
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }
  
    Widget _buildSizeControl() {
      return Row(
        children: [
          const Icon(Icons.photo_size_select_large, color: Colors.purple),
          const SizedBox(width: 16),
          const Text(
            'Taille des sprites:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D3D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              dropdownColor: const Color(0xFF3D3D3D),
              value: spriteWidth,
              underline: const SizedBox(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              onChanged: (int? newValue) {
                setState(() {
                  spriteWidth = newValue!;
                  spriteHeight = newValue;
                });
              },
              items: [16, 32, 64, 128, 256].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value x $value'),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }
  
    Widget _buildAnimationDisplay() {
      var images = _selectedImages.values.toList();
      if (images.isNotEmpty &&
          _currentAnimationIndex >= 0 &&
          _currentAnimationIndex < images.length &&
          images[_currentAnimationIndex] != null) {
        return Image.file(
          File(images[_currentAnimationIndex]!.path),
          fit: BoxFit.cover,
        );
      }
      return const Center(
        child: Text(
          'Aucune image pour l\'animation',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  
    Widget _buildActionButtons() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: nameProject,
            icon: const Icon(Icons.save_alt, color: Colors.white),
            label: const Text(
              "Sauvegarder",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),    
        ],
      );
    }
  
    Widget _buildPreviewSection() {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D3D3D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Prévisualisation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnimationRunning
                          ? const Color(0xFFE91E63)
                          : Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: toggleAnimation,
                    icon: Icon(
                      _isAnimationRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isAnimationRunning ? 'Pause' : 'Démarrer',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildAnimationDisplay(),
              ),
            ),
          ],
        ),
      );
    }
  
    Widget _buildFrameGrid() {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D3D3D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Frames',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3D3D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.grid_view,
                            color: Colors.purple, size: 20),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          dropdownColor: const Color(0xFF3D3D3D),
                          value: 6, 
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          onChanged: (int? newValue) {
                            // Mettre à jour le nombre de colonnes
                          },
                          items: [4, 5, 6, 7, 8].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value colonnes'),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DragTarget<List<dynamic>>(
                onAcceptWithDetails: (details) {
                  String imagePath =
                      '${customPathController.text}/${projectNameController.text}${details.data[0]}';
                  addDroppedImage(imagePath);
                },
                builder: (context, candidateData, rejectedData) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) => _buildFrameItem(index),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  
    Widget _buildFrameItem(int index) {
      if (!_selectedImages.containsKey(index)) {
        return const SizedBox();
      }
  
      return LongPressDraggable<int>(
        data: index,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple, width: 2),
              image: DecorationImage(
                image: FileImage(File(_selectedImages[index]!.path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        child: DragTarget<int>(
          onAcceptWithDetails: (details) => moveImage(details.data, index),
          builder: (context, candidateData, rejectedData) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D3D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4D4D4D)),
                  ),
                  child: _selectedImages[index]?.path != null
                      ? Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.file(
                            File(_selectedImages[index]!.path),
                            fit: BoxFit.cover, 
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Vide',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
                if (_selectedImages[index]?.path != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: Colors.white,
                        onPressed: () => removeImage(index),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }