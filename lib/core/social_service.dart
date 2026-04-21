import '../models/social.dart';
import 'game_service.dart';

/// Architecture: Simplified Social Layer
/// 
/// Focuses on essential XP-based competition and daily challenges.
class SocialService {
  final GameService _gs;
  
  List<Friend> friends = [];
  List<SocialChallenge> activeChallenges = [];

  SocialService(this._gs);

  void init() {
    // Essential Friend List
    friends = [
      Friend(id: 'f1', name: 'Alex', level: 8, xp: 6400, streak: 12),
      Friend(id: 'f2', name: 'Sam',  level: 4, xp: 1800, streak: 4),
    ];

    // Minimal Daily Challenges
    activeChallenges = [
      SocialChallenge(id: 'c1', title: 'Daily XP Goal', description: 'Earn 500 XP', target: 500, metric: 'xp'),
      SocialChallenge(id: 'c2', title: 'Task Streak', description: 'Finish 3 tasks', target: 3, metric: 'tasks'),
    ];
  }

  /// Daily XP Leaderboard (Resets every 24h)
  List<LeaderboardEntry> getDailyLeaderboard() {
    // Fix #3: Realistic Social XP Simulation (Date-seeded variation)
    final now = DateTime.now();
    final seed = now.day + now.month + now.year;
    
    final entries = friends.map((f) {
      // Use friend ID + date seed for consistent but changing daily XP
      final dayVariation = ((f.id.hashCode + seed) % 300) - 150; 
      final baseDailyXp = (f.level * 80) + 100;
      
      return LeaderboardEntry(
        name: f.name,
        value: (baseDailyXp + dayVariation).clamp(50, 2000),
        rank: 0,
      );
    }).toList();

    entries.add(LeaderboardEntry(
      name: 'You',
      value: _gs.user.dailyXp,
      rank: 0,
      isUser: true,
    ));

    entries.sort((a, b) => b.value.compareTo(a.value));
    return List.generate(entries.length, (i) => LeaderboardEntry(
      name: entries[i].name,
      value: entries[i].value,
      rank: i + 1,
      isUser: entries[i].isUser,
    ));
  }

  /// Finds the player just above the user
  LeaderboardEntry? getClosestRival() {
    final board = getDailyLeaderboard();
    final userIndex = board.indexWhere((e) => e.isUser);
    return userIndex > 0 ? board[userIndex - 1] : null;
  }
}
  /// Simple challenge progress update
  void onActivity(String metric, int amount) {
    for (var c in activeChallenges) {
      if (c.metric == metric && !c.completed) {
        c.progress += amount;
        if (c.progress >= c.target) {
          c.completed = true;
          _gs.onMilestone?.call('CHALLENGE COMPLETE: ${c.title}! 🏆');
          _gs.user.addXP(100); 
        }
      }
    }
  }
}
