import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

enum GameTab { quests, character, gym, feats }

class GameBottomNav extends StatelessWidget {
  final GameTab activeTab;
  final ValueChanged<GameTab> onTabChange;

  const GameBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: GameTheme.cardBg,
        border: Border(
          top: BorderSide(color: GameTheme.border, width: 1),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          _buildNavItem(GameTab.quests, Icons.history_edu, 'Quests'),
          _buildNavItem(GameTab.character, Icons.person, 'Character'),
          _buildNavItem(GameTab.gym, Icons.fitness_center, 'Gym'),
          _buildNavItem(GameTab.feats, Icons.workspace_premium, 'Feats'),
        ],
      ),
    );
  }

  Widget _buildNavItem(GameTab tab, IconData icon, String label) {
    final isActive = activeTab == tab;
    final color = isActive ? GameTheme.primary : GameTheme.mutedForeground;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabChange(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  color: GameTheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            const SizedBox(height: 8),
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
