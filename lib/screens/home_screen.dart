import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/game_provider.dart';
import '../models/cat_profile.dart';
import '../models/game_state.dart';
import '../widgets/glass_container.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // final profileProvider = Provider.of<ProfileProvider>(context);

    final isMidnight = themeProvider.currentTheme == DustyTheme.midnight;
    final textColor = isMidnight ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isMidnight ? Colors.white70 : const Color(0xFF334155);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: CustomPaint(
              painter: isMidnight 
                ? CosmicBackgroundPainter() 
                : CloudyBackgroundPainter(),
            ),
          ),
          
          SafeArea(
            bottom: false, // Allow background to reach bottom
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Loaf',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                  ),
                                  Text(
                                    'For your little kittens',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: subTextColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          /*
                          Text(
                            'Active Profile',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor),
                          ),
                          const SizedBox(height: 16),
                          _buildProfileSelector(context, profileProvider, textColor),
                          const SizedBox(height: 32),
                          */
                          Text(
                            'Game Modes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor),
                          ),
                          const SizedBox(height: 16),
                          _buildGameGrid(context, textColor),
                          const SizedBox(height: 24), // Reduced space for bottom alignment
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Celestial Body (Theme Toggle) - Top Layer
          Positioned(
            top: -100,
            right: -100,
            child: GestureDetector(
              onTap: () => themeProvider.toggleTheme(),
              child: SizedBox(
                width: 250,
                height: 250,
                child: CustomPaint(
                  painter: CelestialPainter(isMidnight: isMidnight),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(BuildContext context, ProfileProvider provider, Color textColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...provider.profiles.map((profile) {
            final isActive = provider.activeProfile?.id == profile.id;
            return GestureDetector(
              onTap: () => provider.setActiveProfile(profile),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: profile.color),
                    const SizedBox(width: 8),
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? Colors.white : textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _showAddProfileDialog(context, provider),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: textColor.withOpacity(0.7), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context, Color textColor) {
    final modes = [
      {
        'mode': GameMode.underTheRug,
        'name': 'Under the Rug',
        'icon': Icons.layers,
      },
      {
        'mode': GameMode.bugSwarm,
        'name': 'Bug Swarm',
        'icon': Icons.bug_report,
      },
      {
        'mode': GameMode.laserPath,
        'name': 'Laser Path',
        'icon': Icons.fluorescent,
      },
      // {'mode': GameMode.pondSkater, 'name': 'Pond Skater', 'icon': Icons.water},
      {
        'mode': GameMode.stringFeather,
        'name': 'String & Feather',
        'icon': Icons.gesture,
      },
      {
        'mode': GameMode.whackAMouse,
        'name': 'Whack a Mouse',
        'icon': Icons.pets,
      },
      {
        'mode': GameMode.fishTank,
        'name': 'Fish Tank',
        'icon': Icons.water,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: modes.length,
      itemBuilder: (context, index) {
        final modeData = modes[index];
        return GestureDetector(
          onTap: () {
            Provider.of<GameProvider>(
              context,
              listen: false,
            ).setMode(modeData['mode'] as GameMode);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GameScreen()),
            );
          },
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  modeData['icon'] as IconData,
                  size: 32,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    modeData['name'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddProfileDialog(BuildContext context, ProfileProvider provider) {
    final controller = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('New Kitten Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Kitten Name'),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [Colors.blue, Colors.orange, Colors.pink, Colors.green]
                    .map((color) {
                      return GestureDetector(
                        onTap: () => selectedColor = color,
                        child: CircleAvatar(backgroundColor: color, radius: 15),
                      );
                    })
                    .toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addProfile(
                  CatProfile(
                    id: DateTime.now().toString(),
                    name: controller.text,
                    color: selectedColor,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class CosmicBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Deep Space Gradient
    final gradient = const RadialGradient(
      center: Alignment(0.7, -0.6),
      radius: 1.5,
      colors: [
        Color(0xFF1B1B2F),
        Color(0xFF0D0D17),
        Color(0xFF000000),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = gradient);

    final rand = math.Random(42);

    // 1. Draw Nebula Clouds
    _drawNebula(canvas, size, const Color(0xFF4A148C), 0.15, 200, Offset(size.width * 0.2, size.height * 0.3));
    _drawNebula(canvas, size, const Color(0xFF311B92), 0.1, 250, Offset(size.width * 0.8, size.height * 0.7));
    _drawNebula(canvas, size, const Color(0xFF006064), 0.08, 180, Offset(size.width * 0.5, size.height * 0.5));

    // 2. Draw Distant Star Clusters
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 250; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final radius = rand.nextDouble() * 0.8;
      final opacity = rand.nextDouble() * 0.5 + 0.2;
      
      canvas.drawCircle(
        Offset(x, y), 
        radius, 
        starPaint..color = Colors.white.withOpacity(opacity)
      );
    }

    // 3. Draw Denser Star Clusters (Glowy Stars)
    for (int i = 0; i < 15; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final radius = rand.nextDouble() * 1.5 + 1.0;
      
      final glowPaint = Paint()
        ..color = Colors.blue[100]!.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(x, y), radius * 4, glowPaint);
      canvas.drawCircle(Offset(x, y), radius, starPaint..color = Colors.white);
    }
  }

  void _drawNebula(Canvas canvas, Size size, Color color, double opacity, double radius, Offset center) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);
    
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center + const Offset(100, -50), radius * 0.8, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CloudyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA)],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = gradient);

    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.6);
    final rand = math.Random(123);

    for (int i = 0; i < 8; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height * 0.6;
      _drawCloud(canvas, Offset(x, y), 50 + rand.nextDouble() * 50, cloudPaint);
    }
  }

  @override
  void _drawCloud(Canvas canvas, Offset pos, double size, Paint paint) {
    canvas.drawCircle(pos, size * 0.6, paint);
    canvas.drawCircle(pos + Offset(size * 0.5, 5), size * 0.5, paint);
    canvas.drawCircle(pos - Offset(size * 0.5, 5), size * 0.5, paint);
    canvas.drawCircle(pos + Offset(size * 0.3, -size * 0.3), size * 0.4, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CelestialPainter extends CustomPainter {
  final bool isMidnight;
  CelestialPainter({required this.isMidnight});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (isMidnight) {
      // Draw Moon
      final moonPaint = Paint()
        ..color = Colors.white.withOpacity(0.9);
      
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawCircle(center, radius + 20, glowPaint);
      canvas.drawCircle(center, radius, moonPaint);

      // Draw craters
      final craterPaint = Paint()..color = Colors.black.withOpacity(0.05);
      canvas.drawCircle(center + const Offset(-20, 10), radius * 0.2, craterPaint);
      canvas.drawCircle(center + const Offset(10, -30), radius * 0.15, craterPaint);
      canvas.drawCircle(center + const Offset(30, 40), radius * 0.1, craterPaint);
    } else {
      // Draw Sun
      final sunPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFEA00), Color(0xFFFF9100)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

      canvas.drawCircle(center, radius + 40, glowPaint);
      canvas.drawCircle(center, radius, sunPaint);
      
      // Subtle rays
      final rayPaint = Paint()
        ..color = Colors.orange.withOpacity(0.1)
        ..strokeWidth = 2;
      for (int i = 0; i < 12; i++) {
        final angle = (i * 30) * math.pi / 180;
        canvas.drawLine(
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
          center + Offset(math.cos(angle) * (radius + 30), math.sin(angle) * (radius + 30)),
          rayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
