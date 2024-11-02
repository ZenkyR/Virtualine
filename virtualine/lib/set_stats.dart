import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final eraserState = ValueNotifier<bool>(false);

final colorState = ValueNotifier<int>(0);

final widthState = ValueNotifier<double>(1.0);

final opacityState = ValueNotifier<double>(1.0);

final fullPaintState = ValueNotifier<bool>(false);

final pipetteState = ValueNotifier<bool>(false);

final navIndex = ValueNotifier<int>(0);

final projectPath = ValueNotifier<String>('');

final projectName = ValueNotifier<String>('');

final projectPathSound = ValueNotifier<String>('');

void loadStats() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? savedEraser = prefs.getBool('eraserState');
  int? savedColor = prefs.getInt('colorState');
  double? savedWidth = prefs.getDouble('widthState');
  double? savedOpacity = prefs.getDouble('opacityState');
  bool? savedFullPaint = prefs.getBool('fullPaintState');

  if (savedEraser != null) {
    eraserState.value = savedEraser;
  }

  if (savedColor != null) {
    colorState.value = savedColor;
  }

  if (savedWidth != null) {
    widthState.value = savedWidth;
  }

  if (savedOpacity != null) {
    opacityState.value = savedOpacity;
  }

  if (savedFullPaint != null) {
    fullPaintState.value = savedFullPaint;
  }
}

void saveStats() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('eraserState', eraserState.value);
  await prefs.setInt('colorState', colorState.value);
  await prefs.setDouble('widthState', widthState.value);
  await prefs.setDouble('opacityState', opacityState.value);
  await prefs.setBool('fullPaintState', fullPaintState.value);
}

void loadNavIndex() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? savedIndex = prefs.getInt('navIndex');

  if (savedIndex != null) {
    navIndex.value = savedIndex;
  }
}

void saveNavIndex(int index) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('navIndex', index);
  navIndex.value = index;
}

void resetStats() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('eraserState');
  await prefs.remove('colorState');
  await prefs.remove('widthState');
  await prefs.remove('opacityState');
  await prefs.remove('fullPaintState');
  await prefs.remove('navIndex');
  await prefs.remove('projectPath');
  await prefs.remove('projectName');

  eraserState.value = false;
  colorState.value = 0;
  widthState.value = 1.0;
  opacityState.value = 1.0;
  fullPaintState.value = false;
  navIndex.value = 0;
  projectPath.value = '';
  projectName.value = '';
}
