import 'dart:math';
import '../models/activity.dart';
import '../models/user.dart';

enum MissionType { earnXp, completeTasks, specificStat }

class Mission {
  final String id;
  final String description;
  final MissionType type;
  final int target;
  final String? stat;
  final int rewardXp;
  bool completed;

  Mission({
    required this.id,
    required this.description,
    required this.type,
    required this.target,
    this.stat,
    required this.rewardXp,
    this.completed = false,
  });
}

class MissionService {
  late Mission dailyMission;

  void initDailyMission({
    bool completedOverride = false,
    MissionType? type,
    int? target,
    String? stat,
    required User user,
    required int threshold,
    required List<ActivityType> activityTypes,
  }) {
    if (type != null) {
      dailyMission = Mission(
        id: 'daily',
        description: _getMissionDesc(type, target!, stat),
        type: type,
        target: target,
        stat: stat,
        rewardXp: 20,
        completed: completedOverride,
      );
      return;
    }

    final rand = Random();
    final missionType = MissionType.values[rand.nextInt(MissionType.values.length)];
    int missionTarget = 50;
    String? missionStat;

    switch (missionType) {
      case MissionType.earnXp:
        missionTarget = threshold;
        break;
      case MissionType.completeTasks:
        missionTarget = 2 + (user.level ~/ 5);
        break;
      case MissionType.specificStat:
        missionTarget = 2 + (user.level ~/ 10);
        missionStat = activityTypes[rand.nextInt(activityTypes.length)].stat;
        break;
    }

    dailyMission = Mission(
      id: 'daily',
      description: _getMissionDesc(missionType, missionTarget, missionStat),
      type: missionType,
      target: missionTarget,
      stat: missionStat,
      rewardXp: 20,
      completed: completedOverride,
    );
  }

  String _getMissionDesc(MissionType type, int target, String? stat) {
    switch (type) {
      case MissionType.earnXp: return 'Earn $target XP today';
      case MissionType.completeTasks: return 'Complete $target tasks today';
      case MissionType.specificStat: return 'Gain $target ${stat!} today';
    }
  }

  void checkMission(User user, int dailyProgressXp, int dailyTasksCompleted, Map<String, int> dailyStatGains) {
    if (dailyMission.completed) return;

    bool isDone = false;
    switch (dailyMission.type) {
      case MissionType.earnXp:
        isDone = dailyProgressXp >= dailyMission.target;
        break;
      case MissionType.completeTasks:
        isDone = dailyTasksCompleted >= dailyMission.target;
        break;
      case MissionType.specificStat:
        isDone = (dailyStatGains[dailyMission.stat] ?? 0) >= dailyMission.target;
        break;
    }

    if (isDone) {
      dailyMission.completed = true;
      user.addXP(dailyMission.rewardXp);
    }
  }
}
