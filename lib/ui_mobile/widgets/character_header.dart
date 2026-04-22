import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import 'xp_bar.dart';

class CharacterHeader extends StatelessWidget {
  final String avatar;
  final String name;
  final String title;
  final int level;
  final int xp;
  final int xpToNextLevel;

  const CharacterHeader({
    super.key,
    required this.avatar,
    required this.name,
    required this.title,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Avatar with Level Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GameTheme.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: GameTheme.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatar,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: GameTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: GameTheme.background,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Name and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: GameTheme.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: GameTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                XPBar(
                  current: xp,
                  max: xpToNextLevel,
                  showLabel: false,
                  height: 6,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(color: GameTheme.mutedForeground, fontSize: 10),
                    ),
                    Text(
                      '$xp/$xpToNextLevel XP',
                      style: const TextStyle(color: GameTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
