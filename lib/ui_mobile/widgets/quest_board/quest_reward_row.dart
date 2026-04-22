import 'package:flutter/material.dart';
import '../../theme/game_theme.dart';

class QuestRewardRow extends StatelessWidget {
  final int xp;
  final int statGain;
  final String statName;
  final Color statColor;

  const QuestRewardRow({
    super.key,
    required this.xp,
    required this.statGain,
    required this.statName,
    required this.statColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, color: GameTheme.accent, size: 14),
        const SizedBox(width: 4),
        Text(
          '+$xp XP',
          style: const TextStyle(
            color: GameTheme.accent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: GameTheme.mutedForeground,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.trending_up, color: statColor, size: 14),
        const SizedBox(width: 4),
        Text(
          '+$statGain $statName',
          style: TextStyle(
            color: statColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

