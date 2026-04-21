import 'user.dart';

/// Represents a friend in the social system
class Friend {
  final String id;
  final String name;
  final int level;
  final int xp;
  final int streak;

  Friend({
    required this.id,
    required this.name,
    required this.level,
    required this.xp,
    required this.streak,
  });

  factory Friend.fromUser(User user, String name) {
    return Friend(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      level: user.level,
      xp: user.xp,
      streak: 0, // Mocked for now
    );
  }
}

/// A short-term social or self-challenge
class SocialChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  final String metric; // 'xp', 'tasks', 'streak'
  int progress;
  bool completed;

  SocialChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.metric,
    this.progress = 0,
    this.completed = false,
  });

  double get percent => (progress / target).clamp(0.0, 1.0);
}

/// Leaderboard entry for ranking
class LeaderboardEntry {
  final String name;
  final int value;
  final int rank;
  final bool isUser;

  LeaderboardEntry({
    required this.name,
    required this.value,
    required this.rank,
    this.isUser = false,
  });
}
