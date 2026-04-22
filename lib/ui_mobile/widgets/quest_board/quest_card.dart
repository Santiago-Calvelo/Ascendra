import 'package:flutter/material.dart';
import '../../theme/game_theme.dart';
import '../../theme/archetype.dart';
import '../../../models/task.dart';
import '../../../core/game_service.dart';
import '../../screens/quest_detail_screen.dart';
import 'quest_progress_bar.dart';
import 'quest_reward_row.dart';

class QuestCard extends StatefulWidget {
  final Task task;
  final GameService gs;

  const QuestCard({super.key, required this.task, required this.gs});

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  bool _isPressed = false;

  Color _getZoneColor() {
    switch (widget.task.zone) {
      case 'comfort':
        return GameTheme.zoneComfort;
      case 'growth':
        return GameTheme.zoneGrowth;
      case 'normal':
      case null:
      default:
        return GameTheme.zoneNormal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final zoneColor = _getZoneColor();
    final name = widget.gs.getTaskName(widget.task).replaceAll(RegExp(r'\[(.*?)\]'), r'$1');
    final xp = widget.gs.xpFor(widget.task);
    final statGain = widget.gs.statGainFor(widget.task);
    final isCompleted = widget.task.completed;

    // ── Archetype Engine ───────────────────────────────────────────────────
    final archetype = getArchetype(widget.task);
    final style = getStyle(archetype);
    final statLabel = getStatName(archetype);

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          setState(() => _isPressed = false);
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) => QuestDetailScreen(
                task: widget.task,
                gs: widget.gs,
                zoneColor: zoneColor,
                statName: statLabel,
                statColor: style.primary,
                name: name,
                archetypeStyle: style,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: child,
                );
              },
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GameTheme.cardBg,
                Color(0xFF0B1120),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: zoneColor.withValues(alpha: _isPressed ? 0.35 : 0.12),
                blurRadius: _isPressed ? 28 : 16,
                spreadRadius: _isPressed ? 2 : 0,
              ),
            ],
            border: Border.all(
              color: zoneColor.withValues(alpha: _isPressed ? 0.6 : 0.2),
              width: _isPressed ? 1.5 : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ── Internal Radial Depth Overlay ─────────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.5,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Completion Overlay (green tint, low opacity) ──────────
                if (isCompleted)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.greenAccent.withValues(alpha: 0.04),
                            Colors.green.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Zone Left Accent Bar ──────────────────────────────────
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isPressed ? 8 : 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          zoneColor,
                          zoneColor.withValues(alpha: 0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: zoneColor.withValues(alpha: _isPressed ? 0.7 : 0.4),
                          blurRadius: _isPressed ? 16 : 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Main Content ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header: RPG Icon + Title ──────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RPG Icon from Archetype Engine
                          buildRpgIcon(style, isCompleted, size: 56),
                          const SizedBox(width: 14),
                          // Title — offset slightly for asymmetry
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.toUpperCase(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: isCompleted
                                          ? GameTheme.mutedForeground
                                          : GameTheme.foreground,
                                      letterSpacing: 0.3,
                                      height: 1.1,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // Archetype label — tertiary, muted
                                  Row(
                                    children: [
                                      Text(
                                        style.label,
                                        style: TextStyle(
                                          color: style.primary.withValues(alpha: 0.6),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      Text(
                                        '  ·  ${widget.task.zone?.toUpperCase() ?? "NORMAL"}',
                                        style: TextStyle(
                                          color: zoneColor.withValues(alpha: 0.45),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Rewards (secondary, left-aligned) ────────────────
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: QuestRewardRow(
                          xp: xp,
                          statGain: statGain,
                          statName: statLabel,
                          statColor: style.primary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── DOMINANT: Progress Bar ────────────────────────────
                      QuestProgressBar(
                        progress: widget.task.progress.toDouble(),
                        target: widget.task.target.toDouble(),
                        color: style.primary,
                        glowColor: style.glow,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
