enum GameMode {
  underTheRug,
  bugSwarm,
  laserPath,
  pondSkater,
  stringFeather,
  whackAMouse,
  fishTank,
}

class GameState {
  final GameMode mode;
  final bool isPaused;
  final int score;

  GameState({
    required this.mode,
    this.isPaused = false,
    this.score = 0,
  });

  GameState copyWith({
    GameMode? mode,
    bool? isPaused,
    int? score,
  }) {
    return GameState(
      mode: mode ?? this.mode,
      isPaused: isPaused ?? this.isPaused,
      score: score ?? this.score,
    );
  }
}
