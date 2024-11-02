import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<void> loadPathProject(TextEditingController customPathController,
    Function listDirectories) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedPath = prefs.getString('projectPath');

  if (savedPath != null) {
    customPathController.text = savedPath;
    listDirectories(savedPath);
  }
}

void savePathProject(String path) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('projectPath', path);
}

Future<void> loadProjectName(TextEditingController projectName) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedName = prefs.getString('projectName');

  if (savedName != null) {
    projectName.text = savedName;
  }
}

void saveProjectName(TextEditingController projectName) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('projectName', projectName.text);
}

totalPath() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? pathProject = prefs.getString('projectPath');
  String? projectName = prefs.getString('projectName');

  String totalPath = '$pathProject/$projectName';
  return totalPath;
}

Future<List<List>> loadPathDirectory(
    TextEditingController customPathController,
    Function listDirectories) async {
  String? path = await totalPath();

  String? pathTotal = path! + customPathController.text;

  List<List> result = listDirectoriesRecursive(pathTotal).children
      .map((node) => [node.name, node.type])
      .toList();

  return result;
}

Future<void> chooseDirectory(TextEditingController customPathController,
    Function listDirectories) async {
  String? directoryPath = await FilePicker.platform.getDirectoryPath();
  if (directoryPath != null) {
    customPathController.text = directoryPath;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('projectPath', directoryPath);
  }
  listDirectories(customPathController.text);
}

class Node {
  String name;
  int type; 
  List<Node> children = [];

  Node(this.name, this.type);

  void addChild(Node child) {
    children.add(child);
  }
}

Node listDirectoriesRecursive(String pathString, [Node? parentNode]) {
  String directoryPath = pathString;
  Node rootNode = parentNode ?? Node(path.basename(directoryPath), 2);

  if (directoryPath.isNotEmpty) {
    Directory directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      return rootNode;
    }
    List<FileSystemEntity> entities = directory.listSync();
    for (FileSystemEntity entity in entities) {
      int entityType = FileSystemEntity.isDirectorySync(entity.path) ? 2 : 1;
      Node entityNode = Node(path.basename(entity.path), entityType);
      rootNode.addChild(entityNode);
      if (entityType == 2) {
        listDirectoriesRecursive(entity.path, entityNode);
      }
    }
  }

  return rootNode;
}


List<String> listDirectories(String pathString) {
  String directoryPath = pathString;
  List<String> directories = [];

  if (directoryPath.isNotEmpty) {
    Directory directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      return directories;
    }
    List<FileSystemEntity> entities = directory.listSync(followLinks: false);

    directories = entities
        .whereType<Directory>()
        .map((entity) => path.basename(entity.path))
        .toList();
  }

  return directories;
}

Future<void> createDirectory(
    TextEditingController customPathController,
    TextEditingController projectNameController,
    Function listDirectories,
    BuildContext context) async {
  if (projectNameController.text.isEmpty) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: const Text('Veuillez entrer un nom pour le dossier'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return;
  }

  String projectPath = customPathController.text;
  String projectName = projectNameController.text;
  String newProjectPath = path.join(projectPath, projectName);

  if (Directory(newProjectPath).existsSync()) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: const Text('Un dossier avec ce nom existe déjà'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return;
  }
  Directory(newProjectPath).createSync(recursive: true);

  listDirectories(projectPath);
}
