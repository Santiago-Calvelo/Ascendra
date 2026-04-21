import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class XPBar extends StatelessWidget {
  final int current;
  final int max;
  final bool showLabel;
  final double height;

  const XPBar({
    super.key,
    required this.current,
    required this.max,
    this.showLabel = true,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (current / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text(
                'Progress',
                style: TextStyle(color: GameTheme.mutedForeground, fontSize: 11),
              ),
              Text(
                '$current / $max XP',
                style: const TextStyle(color: GameTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: GameTheme.border,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * percentage,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [GameTheme.primary, GameTheme.accent],
                      ),
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
