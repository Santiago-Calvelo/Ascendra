import 'package:flutter/material.dart';
import '../../theme/game_theme.dart';
import '../../../core/game_service.dart';

class QuestHeader extends StatelessWidget {
  final GameService gs;

  const QuestHeader({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    final currentXp = gs.user.xp;
    final nextLevelXp = (gs.user.level * gs.user.level * 100); 
    final progress = (currentXp / (nextLevelXp == 0 ? 1 : nextLevelXp)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 48),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.6),
          radius: 1.2,
          colors: [
            Color(0xFF1E293B), // Slightly lighter core
            Color(0xFF020617), // Near black edges
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                // Larger Avatar with Directional Glow
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [GameTheme.accent, Color(0xFFB45309)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameTheme.accent.withValues(alpha: 0.5),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, -4), // Directional: stronger at top
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: GameTheme.cardBg,
                      ),
                      child: const Center(
                        child: Text('⚔️', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IRON SENTINEL',
                        style: TextStyle(
                          color: GameTheme.accent.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Arthor',
                        style: TextStyle(
                          color: GameTheme.foreground,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Level Badge with Asymmetry
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              GameTheme.accent.withValues(alpha: 0.2),
                              GameTheme.accent.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: GameTheme.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'LVL ${gs.user.level}',
                          style: const TextStyle(
                            color: GameTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            // XP Bar with "Tube" Effect
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, left: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STRENGTH EXPERIENCE',
                        style: TextStyle(
                          color: GameTheme.mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        '$currentXp / $nextLevelXp',
                        style: const TextStyle(
                          color: GameTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            height: 16,
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFDE68A), // Light top
                                  GameTheme.accent,   // Core
                                  Color(0xFFB45309), // Dark bottom
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: GameTheme.accent.withValues(alpha: 0.6),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          // Glass highlight
                          Positioned(
                            top: 2,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
