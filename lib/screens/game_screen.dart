import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/game_canvas.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final state = gameProvider.state;

    return Scaffold(
      body: Stack(
        children: [
          // Game Surface
          Positioned.fill(
            child: GameCanvas(mode: state.mode),
          ),
          
          // UI Overlays
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const GlassContainer(
                          padding: EdgeInsets.all(12),
                          borderRadius: 30,
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        borderRadius: 30,
                        child: Text(
                          _getModeName(state.mode),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => gameProvider.togglePause(),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 30,
                          child: Icon(
                            state.isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (state.isPaused)
            Container(
              color: Colors.black54,
              child: Center(
                child: SingleChildScrollView(
                  child: GlassContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PAUSED',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => gameProvider.togglePause(),
                        child: const Text('Resume'),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
        ],
      ),
    );
  }

  String _getModeName(GameMode mode) {
    switch (mode) {
      case GameMode.underTheRug: return 'Under the Rug';
      case GameMode.bugSwarm: return 'Bug Swarm';
      case GameMode.laserPath: return 'Laser Path';
      case GameMode.pondSkater: return 'Pond Skater';
      case GameMode.stringFeather: return 'String & Feather';
    }
  }
}
