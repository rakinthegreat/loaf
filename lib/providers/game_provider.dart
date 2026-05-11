import 'package:flutter/material.dart';
import '../models/game_state.dart';

class GameProvider with ChangeNotifier {
  GameState _state = GameState(mode: GameMode.underTheRug);

  GameState get state => _state;

  void setMode(GameMode mode) {
    _state = _state.copyWith(mode: mode);
    notifyListeners();
  }

  void togglePause() {
    _state = _state.copyWith(isPaused: !_state.isPaused);
    notifyListeners();
  }

  void updateScore(int delta) {
    _state = _state.copyWith(score: _state.score + delta);
    notifyListeners();
  }

  void resetGame() {
    _state = GameState(mode: _state.mode);
    notifyListeners();
  }
}
