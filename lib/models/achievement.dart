enum RewardType { xpMultiplier, statBonus, none }

class Achievement {
  final String id;
  final String title;
  final String description;
  final int target;
  final RewardType rewardType;
  final double rewardValue;
  int progress;
  bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.rewardType = RewardType.none,
    this.rewardValue = 0,
    this.progress = 0,
    this.unlocked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'progress': progress, 'unlocked': unlocked,
  };
}
