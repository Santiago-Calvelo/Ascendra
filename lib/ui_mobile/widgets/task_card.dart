import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

enum ZoneType { comfort, normal, growth }
enum ActivityType { steps, cardio, gym, focus }

class TaskCard extends StatefulWidget {
  final String name;
  final int progress;
  final int target;
  final int xpReward;
  final int statAmount;
  final String statReward;
  final ZoneType zone;
  final ActivityType activityType;
  final bool completed;
  final VoidCallback onSelect;
  final int index;

  const TaskCard({
    super.key,
    required this.name,
    required this.progress,
    required this.target,
    required this.xpReward,
    required this.statAmount,
    required this.statReward,
    required this.zone,
    required this.activityType,
    required this.completed,
    required this.onSelect,
    required this.index,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  Color _getZoneColor() {
    switch (widget.zone) {
      case ZoneType.comfort:
        return const Color(0xFF10B981); // Emerald
      case ZoneType.normal:
        return const Color(0xFF3B82F6); // Blue
      case ZoneType.growth:
        return const Color(0xFFF43F5E); // Rose
    }
  }

  IconData _getActivityIcon() {
    switch (widget.activityType) {
      case ActivityType.steps:
        return Icons.directions_walk;
      case ActivityType.cardio:
        return Icons.timer;
      case ActivityType.gym:
        return Icons.fitness_center;
      case ActivityType.focus:
        return Icons.psychology;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (widget.progress / widget.target).clamp(0.0, 1.0);
    final zoneColor = _getZoneColor();
    final isGrowth = widget.zone == ZoneType.growth;
    final isComfort = widget.zone == ZoneType.comfort;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Opacity(
        opacity: widget.completed ? 0.6 : 1.0,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.completed ? null : widget.onSelect,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: widget.completed ? GameTheme.cardBg.withOpacity(0.4) : GameTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.completed 
                    ? zoneColor.withOpacity(0.3) 
                    : (isGrowth ? zoneColor.withOpacity(0.5) : GameTheme.border),
                width: isGrowth ? 1.5 : 1.0,
              ),
              boxShadow: widget.completed ? [
                BoxShadow(
                  color: zoneColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: -2,
                )
              ] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Zone Accent Strip (Replaces IntrinsicHeight logic with Stack + Positioned)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: isGrowth ? 6 : 4,
                      decoration: BoxDecoration(
                        color: isComfort ? zoneColor.withOpacity(0.7) : zoneColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8), // Padding from the strip
                            // Icon Container
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: GameTheme.background.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: widget.completed ? Border.all(color: zoneColor.withOpacity(0.5)) : null,
                              ),
                              child: Icon(
                                widget.completed ? Icons.check_circle : _getActivityIcon(),
                                size: 18,
                                color: widget.completed ? zoneColor : GameTheme.foreground.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.name,
                                    style: TextStyle(
                                      color: GameTheme.foreground,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.1,
                                      decoration: widget.completed ? TextDecoration.lineThrough : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '+${widget.xpReward} XP',
                                        style: const TextStyle(color: GameTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 2,
                                        height: 2,
                                        decoration: const BoxDecoration(color: GameTheme.mutedForeground, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+${widget.statAmount} ${widget.statReward.substring(0, 3).toUpperCase()}',
                                        style: const TextStyle(color: GameTheme.accent, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!widget.completed)
                              const Icon(Icons.chevron_right, color: GameTheme.mutedForeground, size: 16),
                          ],
                        ),
                        // Progress Bar (if not completed)
                        if (!widget.completed) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 56),
                            child: Row(
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Container(
                                        height: 6,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: GameTheme.background,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Stack(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 500),
                                              curve: Curves.easeOut,
                                              width: constraints.maxWidth * progressPercent,
                                              decoration: BoxDecoration(
                                                color: zoneColor,
                                                borderRadius: BorderRadius.circular(3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: zoneColor.withOpacity(0.3),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(progressPercent * 100).toInt()}%',
                                  style: const TextStyle(color: GameTheme.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
