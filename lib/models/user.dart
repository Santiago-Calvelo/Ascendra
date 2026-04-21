import 'dart:math';

/// Essential behavior metrics for adaptive difficulty.
class ActivityMetric {
  final String activityId;
  int streak;        // Positive for success, negative for failure
  double multiplier; // Difficulty scaler (0.7x to 3.0x)

  ActivityMetric({
    required this.activityId,
    this.streak = 0,
    this.multiplier = 1.0,
  });

  /// Simple streak-based adjustment: +/- 0.1 every 3 days.
  void updatePerformance(bool success) {
    if (success) {
      streak = streak < 0 ? 1 : streak + 1;
      if (streak >= 3) {
        multiplier = (multiplier + 0.1).clamp(0.7, 3.0);
        streak = 0;
      }
    } else {
      streak = streak > 0 ? -1 : streak - 1;
      if (streak <= -3) {
        multiplier = (multiplier - 0.1).clamp(0.7, 3.0);
        streak = 0;
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'activityId': activityId,
    'streak': streak,
    'multiplier': multiplier,
  };

  factory ActivityMetric.fromJson(Map<String, dynamic> json) => ActivityMetric(
    activityId: json['activityId'],
    streak: json['streak'] ?? 0,
    multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
  );
}

class User {
  int xp;
  int level;
  int lifetimeTasks;
  int dailyXp = 0;
  DateTime lastActiveTime = DateTime.now();
  final Map<String, int> stats;
  final Map<String, ActivityMetric> behavior;

  User({
    this.xp = 0,
    this.level = 1,
    this.lifetimeTasks = 0,
    this.dailyXp = 0,
    DateTime? lastActiveTime,
    Map<String, int>? stats,
    Map<String, ActivityMetric>? behavior,
  })  : stats = stats ?? {'fuerza': 1, 'resistencia': 1, 'disciplina': 1},
        behavior = behavior ?? {},
        lastActiveTime = lastActiveTime ?? DateTime.now();

  ActivityMetric getMetric(String aid) => behavior.putIfAbsent(aid, () => ActivityMetric(activityId: aid));

  void addXP(int amount) {
    xp += amount;
    dailyXp += amount;
    lastActiveTime = DateTime.now();
    level = (sqrt(xp / 100)).floor() + 1;
  }

  void removeXP(int amount) {
    xp = (xp - amount).clamp(0, 999999);
    dailyXp = (dailyXp - amount).clamp(0, 999999);
    level = (sqrt(xp / 100)).floor() + 1;
  }

  void incrementStat(String stat, int amount) => stats[stat] = (stats[stat] ?? 1) + amount;
  void decrementStat(String stat, int amount) => stats[stat] = ((stats[stat] ?? 1) - amount).clamp(1, 999);

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'level': level,
    'lifetimeTasks': lifetimeTasks,
    'dailyXp': dailyXp,
    'lastActiveTime': lastActiveTime.toIso8601String(),
    'stats': stats,
    'behavior': behavior.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    xp: json['xp'] ?? 0,
    level: json['level'] ?? 1,
    lifetimeTasks: json['lifetimeTasks'] ?? 0,
    dailyXp: json['dailyXp'] ?? 0,
    lastActiveTime: DateTime.tryParse(json['lastActiveTime'] ?? '') ?? DateTime.now(),
    stats: Map<String, int>.from(json['stats'] ?? {}),
    behavior: (json['behavior'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, ActivityMetric.fromJson(v))),
  );
}
