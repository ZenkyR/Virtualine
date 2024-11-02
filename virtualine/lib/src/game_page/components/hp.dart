import 'dart:async';

class HPManager {
  int maxHP;
  late int _currentHP;
  final _hpController = StreamController<int>.broadcast();

  HPManager({required this.maxHP}) {
    _currentHP = maxHP;
  }

  int get currentHP => _currentHP;
  Stream<int> get hpStream => _hpController.stream;

  void reduceHP(int amount) {
    _currentHP = (_currentHP - amount).clamp(0, maxHP);
    _hpController.sink.add(_currentHP);
  }

  void healHP(int amount) {
    _currentHP = (_currentHP + amount).clamp(0, maxHP);
    _hpController.sink.add(_currentHP);
  }

  void dispose() {
    _hpController.close();
  }

  void resetHP() {
    _currentHP = maxHP;
    _hpController.sink.add(_currentHP);
  }

  void setCurrentHP(int hp) {
    _currentHP = hp;
    _hpController.sink.add(_currentHP);
  }
}