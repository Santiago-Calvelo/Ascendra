import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../theme/archetype.dart';
import '../../models/task.dart';
import '../../core/game_service.dart';
import 'workout/routine_builder_screen.dart';
import 'workout/workout_execution_screen.dart';
import '../../models/workout/workout_models.dart' as wm;

class QuestDetailScreen extends StatelessWidget {
  final Task task;
  final GameService gs;
  final Color zoneColor;
  final String statName;
  final Color statColor;
  final String name;
  final ArchetypeStyle archetypeStyle;

  const QuestDetailScreen({
    super.key,
    required this.task,
    required this.gs,
    required this.zoneColor,
    required this.statName,
    required this.statColor,
    required this.name,
    required this.archetypeStyle,
  });

  @override
  Widget build(BuildContext context) {
    final xp = gs.xpFor(task);
    final statGain = gs.statGainFor(task);
    final isCompleted = task.completed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameTheme.background,
              Color(0xFF020617),
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: GameTheme.foreground),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero RPG Icon ─────────────────────────────────────
                    Center(
                      child: buildRpgIcon(archetypeStyle, isCompleted, size: 100),
                    ),
                    const SizedBox(height: 40),

                    // ── Title ─────────────────────────────────────────────
                    Center(
                      child: Text(
                        name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameTheme.foreground,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Zone + Archetype Tags ─────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTag(
                            archetypeStyle.label,
                            archetypeStyle.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildTag(
                            '${task.zone?.toUpperCase() ?? "NORMAL"} ZONE',
                            zoneColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ── Rewards ───────────────────────────────────────────
                    const Text(
                      'ESTIMATED REWARDS',
                      style: TextStyle(
                        color: GameTheme.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            GameTheme.cardBg,
                            GameTheme.cardBg.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GameTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: archetypeStyle.glow.withValues(alpha: 0.08),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRewardItem(Icons.star, '+$xp XP', GameTheme.accent),
                          Container(width: 1.5, height: 50, color: GameTheme.border),
                          _buildRewardItem(
                            Icons.trending_up,
                            '+$statGain $statName',
                            archetypeStyle.primary,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Begin Quest Button ────────────────────────────────
                    _BeginQuestButton(
                      color: archetypeStyle.primary,
                      glowColor: archetypeStyle.glow,
                      onTap: () {
                        if (task.activityId.contains('gym')) {
                          _startWorkoutFromQuest(context);
                        } else {
                          gs.toggleTask(task);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkoutFromQuest(BuildContext context) {
    // Generate a routine linked to this quest
    final routine = wm.Routine(
      id: 'routine_${task.id}',
      name: 'DAILY GYM CHALLENGE',
      exercises: [
        wm.Exercise(
          id: 'ex_target',
          name: 'Main Exercise',
          category: 'strength',
          sets: List.generate(task.target, (i) => wm.WorkoutSet(reps: 10, weight: 60)),
          restSeconds: 90,
        ),
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutExecutionScreen(
          routine: routine,
          gameService: gs,
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildRewardItem(IconData iconData, String label, Color color) {
    return Column(
      children: [
        Icon(iconData, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _BeginQuestButton extends StatefulWidget {
  final Color color;
  final Color glowColor;
  final VoidCallback onTap;

  const _BeginQuestButton({
    required this.color,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_BeginQuestButton> createState() => _BeginQuestButtonState();
}

class _BeginQuestButtonState extends State<_BeginQuestButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _isPressed ? 0.55 : 0.35),
                blurRadius: _isPressed ? 28 : 20,
                spreadRadius: _isPressed ? 3 : 2,
              ),
              if (_isPressed)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: const Center(
            child: Text(
              'BEGIN QUEST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
