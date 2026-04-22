import 'package:flutter/material.dart';
import '../../core/game_service.dart';
import '../theme/game_theme.dart';
import '../widgets/quest_board/quest_header.dart';
import '../widgets/quest_board/quest_card.dart';

class QuestBoardScreen extends StatelessWidget {
  final GameService gs;

  const QuestBoardScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Base Background ───────────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF020617), // Near-void
                ],
              ),
            ),
          ),
        ),

        // ── Vignette Overlay (darkens edges) ─────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ── Main Content ──────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestHeader(gs: gs),
            Expanded(
              child: gs.tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'NO ACTIVE QUESTS',
                        style: TextStyle(
                          color: GameTheme.mutedForeground,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      itemCount: gs.tasks.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 0, 20),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: GameTheme.accent,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: GameTheme.accent.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'ACTIVE QUESTS',
                                  style: TextStyle(
                                    color: GameTheme.mutedForeground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final task = gs.tasks[i - 1];
                        return QuestCard(task: task, gs: gs);
                      },
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
