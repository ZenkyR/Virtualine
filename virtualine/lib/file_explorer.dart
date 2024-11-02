// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:virtualine/search_directory.dart';

class FileExplorer extends StatefulWidget {
  final String initialPath;
  final IconData folderIcon;
  final IconData fileIcon;
  final String title;
  final bool Function(String)? fileFilter;
  final Function(List<dynamic>)? onFileTap;
  final bool allowDrag;
  final Function(String)? onPathChanged;

  const FileExplorer({
    super.key,
    required this.initialPath,
    this.folderIcon = Icons.folder,
    this.fileIcon = Icons.insert_drive_file,
    this.title = 'Explorateur de fichiers',
    this.fileFilter,
    this.onFileTap,
    this.allowDrag = true,
    this.onPathChanged,
  });

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  final TextEditingController _customPathController = TextEditingController();
  final TextEditingController _newFolderController = TextEditingController();
  final List<String> _directoryStack = [];
  StreamSubscription<FileSystemEvent>? _directoryWatcherSubscription;
  bool _isExpanded = true;
  List<List<dynamic>>? _currentDirectoryContents;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeExplorer();
  }

  Future<String> getFullPath(String relativePath) async {
    final base = await totalPath();
    return '$base$relativePath';
  }

  void _initializeExplorer() {
    _customPathController.text = widget.initialPath;
    _directoryStack.add(widget.initialPath);
    _loadDirectory();
    _startDirectoryWatcher();
  }

  Future<void> _createNewFolder() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Nouveau dossier',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _newFolderController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nom du dossier',
            hintStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.purple)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _newFolderController.text),
            child: const Text('Créer', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final fullPath =
          await getFullPath('${_customPathController.text}/$result');
      try {
        await Directory(fullPath).create();
        _loadDirectory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur lors de la création du dossier: $e')),
          );
        }
      }
      _newFolderController.clear();
    }
  }

  Future<String> _getItemFullPath(String itemName) async {
    final base = await totalPath();
    return '$base${_customPathController.text}/$itemName';
  }

  Future<String> _getItemRelativePath(String itemName) async {
    final base = await totalPath();
    final fullPath = '$base${_customPathController.text}/$itemName';

    final relativePath = fullPath.replaceFirst(base, '');
    return relativePath;
  }

  Widget _buildFileTile(List<dynamic> item, IconData icon) {
    return FutureBuilder<List<String>>(
      future: Future.wait([
        _getItemRelativePath(item[0].toString()),
        _getItemFullPath(item[0].toString()),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();

        final relativePath = snapshot.data![0];
        final fullPath = snapshot.data![1];

        final tile = ListTile(
          leading: Icon(icon, color: Colors.purple.shade300),
          title: Text(
            item[0].toString(),
            style: const TextStyle(color: Colors.white),
          ),
          onTap: widget.onFileTap != null
              ? () => widget.onFileTap!([relativePath])
              : null,
        );

        if (!widget.allowDrag) return tile;

        return Draggable(
          data: [relativePath, item[0].toString(), fullPath],
          feedback: Material(
            color: Colors.transparent,
            child: Icon(icon, color: Colors.purple, size: 40),
          ),
          child: tile,
        );
      },
    );
  }

  Widget _buildDirectoryTile(List<dynamic> item) {
    return FutureBuilder<String>(
      future: _getItemFullPath(item[0].toString()),
      builder: (context, snapshot) {
        final fullPath = snapshot.data;

        return DragTarget<List<dynamic>>(
          onWillAcceptWithDetails: (data) => fullPath != null,
          onAcceptWithDetails: (data) async {
            if (fullPath == null) return;

            final String sourceFile = data.data[2];
            final String fileName = data.data[1];
            final String destinationFile = '$fullPath/$fileName';

            try {
              await File(sourceFile).rename(destinationFile);
              _loadDirectory();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors du déplacement: $e')),
                );
              }
            }
          },
          builder: (context, candidateData, rejectedData) {
            return ListTile(
              leading: Icon(widget.folderIcon, color: Colors.purple.shade300),
              title: Text(
                item[0].toString(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                if (fullPath == null) return;
                setState(() {
                  _customPathController.text =
                      '${_customPathController.text}/${item[0]}';
                  _directoryStack.add(_customPathController.text);
                  _loadDirectory();
                  if (widget.onPathChanged != null) {
                    widget.onPathChanged!(_customPathController.text);
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  Future<String> _getParentPath() async {
    final base = await totalPath();
    final currentPath = _customPathController.text;
    final parentPath = currentPath.substring(0, currentPath.lastIndexOf('/'));
    return '$base$parentPath';
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_currentDirectoryContents == null) {
      return const Center(
        child: Text(
          'Aucun fichier trouvé',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: _currentDirectoryContents!.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return DragTarget<List<dynamic>>(
                onWillAcceptWithDetails: (data) => _directoryStack.length > 1,
                onAcceptWithDetails: (data) async {
                  if (_directoryStack.length <= 1) return;

                  final String sourceFile = data.data[2];
                  final String fileName = data.data[1];
                  final parentPath = await _getParentPath();
                  final destinationFile = '$parentPath/$fileName';

                  try {
                    await File(sourceFile).rename(destinationFile);
                    _loadDirectory();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Erreur lors du déplacement: $e')),
                      );
                    }
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return ListTile(
                    leading:
                        const Icon(Icons.arrow_upward, color: Colors.purple),
                    title: const Text('...',
                        style: TextStyle(color: Colors.white70)),
                    onTap: _navigateBack,
                    enabled: _directoryStack.length > 1,
                  );
                },
              );
            }

            final item = _currentDirectoryContents![index - 1];
            final isDirectory = item[1] == 2;

            return isDirectory
                ? _buildDirectoryTile(item)
                : _buildFileTile(item, _getFileIcon(item[0].toString()));
          },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.create_new_folder, color: Colors.purple),
            onPressed: _createNewFolder,
            tooltip: 'Nouveau dossier',
          ),
        ),
      ],
    );
  }

  void _loadDirectory() async {
    if (!_isExpanded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final directoryContents =
          await loadPathDirectory(_customPathController, _listDirectories);
      if (mounted) {
        setState(() {
          _currentDirectoryContents = directoryContents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentDirectoryContents = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<Node> _listDirectories(String pathString) async {
    return listDirectoriesRecursive(pathString);
  }

  void _startDirectoryWatcher() {
    _stopDirectoryWatcher();

    totalPath().then((resolvedPath) {
      final path = resolvedPath + _customPathController.text;
      debugPrint('Watching directory: $path');

      _directoryWatcherSubscription =
          Directory(path).watch(recursive: true).listen((event) {
        _loadDirectory();
      }, onError: (error) {
        debugPrint('Directory watcher error: $error');
      });
    });
  }

  void _stopDirectoryWatcher() {
    _directoryWatcherSubscription?.cancel();
    _directoryWatcherSubscription = null;
  }

  void _navigateBack() {
    if (_directoryStack.length > 1) {
      setState(() {
        _directoryStack.removeLast();
        _customPathController.text = _directoryStack.last;
        _loadDirectory();
      });
    }
  }

  IconData _getFileIcon(String fileName) {
    if (widget.fileFilter != null && !widget.fileFilter!(fileName)) {
      return Icons.block;
    }
    return widget.fileIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (value) {
          setState(() {
            _isExpanded = value;
            if (value) {
              _loadDirectory();
            }
          });
        },
        leading: Icon(widget.folderIcon, color: Colors.purple),
        title: Text(
          widget.title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          SizedBox(
            height: 250,
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customPathController.dispose();
    _stopDirectoryWatcher();
    super.dispose();
  }
}
