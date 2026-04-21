import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../widgets/game_bottom_nav.dart';
import '../widgets/character_header.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameTab _activeTab = GameTab.quests;

  // Mock Character Data
  final Map<String, dynamic> _mockCharacter = {
    'name': 'Arthor',
    'title': 'Wandering Squire',
    'avatar': '⚔️',
    'level': 5,
    'xp': 450,
    'xpToNextLevel': 1000,
  };

  // Mock Tasks Data
  final List<Map<String, dynamic>> _mockTasks = [
    {
      'name': 'Morning Jog',
      'progress': 3500,
      'target': 5000,
      'xpReward': 50,
      'statAmount': 2,
      'statReward': 'endurance',
      'zone': ZoneType.comfort,
      'activityType': ActivityType.steps,
      'completed': false,
    },
    {
      'name': 'Strength Training',
      'progress': 1,
      'target': 3,
      'xpReward': 100,
      'statAmount': 5,
      'statReward': 'strength',
      'zone': ZoneType.normal,
      'activityType': ActivityType.gym,
      'completed': false,
    },
    {
      'name': 'Focused Study',
      'progress': 45,
      'target': 60,
      'xpReward': 75,
      'statAmount': 3,
      'statReward': 'discipline',
      'zone': ZoneType.growth,
      'activityType': ActivityType.focus,
      'completed': false,
    },
    {
      'name': 'Evening Meditation',
      'progress': 15,
      'target': 15,
      'xpReward': 40,
      'statAmount': 2,
      'statReward': 'wisdom',
      'zone': ZoneType.comfort,
      'activityType': ActivityType.focus,
      'completed': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildTabContent(_activeTab),
        ),
      ),
      bottomNavigationBar: GameBottomNav(
        activeTab: _activeTab,
        onTabChange: (tab) {
          setState(() {
            _activeTab = tab;
          });
        },
      ),
    );
  }

  Widget _buildTabContent(GameTab tab) {
    switch (tab) {
      case GameTab.quests:
        return QuestsTab(
          character: _mockCharacter,
          tasks: _mockTasks,
        );
      case GameTab.character:
        return const Center(child: Text('Character Info Screen', style: TextStyle(color: GameTheme.foreground)));
      case GameTab.arena:
        return const Center(child: Text('Arena / Leaderboard', style: TextStyle(color: GameTheme.foreground)));
      case GameTab.feats:
        return const Center(child: Text('Feats / Achievements', style: TextStyle(color: GameTheme.foreground)));
    }
  }
}

class QuestsTab extends StatelessWidget {
  final Map<String, dynamic> character;
  final List<Map<String, dynamic>> tasks;

  const QuestsTab({
    super.key,
    required this.character,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = tasks.where((t) => t['completed'] == true).length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: tasks.length + 3, // Header + Spacer + Title + Tasks
      itemBuilder: (context, index) {
        if (index == 0) {
          return CharacterHeader(
            avatar: character['avatar'],
            name: character['name'],
            title: character['title'],
            level: character['level'],
            xp: character['xp'],
            xpToNextLevel: character['xpToNextLevel'],
          );
        }
        if (index == 1) return const SizedBox(height: 24);
        if (index == 2) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text(
                  'DAILY QUESTS',
                  style: TextStyle(
                    color: GameTheme.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '$completedCount/${tasks.length}',
                  style: const TextStyle(
                    color: GameTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
        
        final taskIndex = index - 3;
        final task = tasks[taskIndex];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TaskCard(
            index: taskIndex,
            name: task['name'],
            progress: task['progress'],
            target: task['target'],
            xpReward: task['xpReward'],
            statAmount: task['statAmount'],
            statReward: task['statReward'],
            zone: task['zone'],
            activityType: task['activityType'],
            completed: task['completed'],
            onSelect: () {
              debugPrint('Selected task: ${task['name']}');
            },
          ),
        );
      },
    );
  }
}
