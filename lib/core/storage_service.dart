import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_service.dart';
import '../models/user.dart';
import '../models/task.dart';
import 'mission_service.dart';
import '../models/workout.dart';
import '../models/achievement.dart';

class StorageService {
  static const _keyUserXp         = 'user_xp';
  static const _keyUserStats       = 'user_stats';
  static const _keyTasks           = 'tasks';
  static const _keyStreak          = 'streak';
  static const _keyLifetimeTasks   = 'lifetime_tasks';
  static const _keyLifetimeGymSets = 'lifetime_gym_sets';
  static const _keyLastCompleted   = 'last_completed_date';
  static const _keyDailyXp           = 'daily_progress_xp';
  static const _keyDailyTasks        = 'daily_tasks_completed';
  static const _keyDailyStatGains    = 'daily_stat_gains';
  static const _keyMissionDate        = 'mission_date';
  static const _keyMissionType        = 'mission_type';
  static const _keyMissionTarget      = 'mission_target';
  static const _keyMissionStat        = 'mission_stat';
  static const _keyMissionCompleted   = 'mission_completed';
  static const _keyIsFocus            = 'is_focus_mode';
  static const _keyFocusDuration      = 'focus_duration';
  static const _keyFocusStart         = 'focus_start_time';
  static const _keyWorkoutHistory      = 'workout_history';
  static const _keyAchievements        = 'achievements';
  static const _keyHealthSyncTime      = 'health_sync_time';
  static const _keyHealthTotalSteps    = 'health_total_steps';

  Future<void> load(GameService gs) async {
    final prefs = await SharedPreferences.getInstance();

    gs.user.xp = prefs.getInt(_keyUserXp) ?? 0;
    gs.user.lifetimeTasks = prefs.getInt(_keyLifetimeTasks) ?? 0;
    gs.user.lifetimeGymSets = prefs.getInt(_keyLifetimeGymSets) ?? 0;
    gs.user.recalcLevel();
    final statsJson = prefs.getString(_keyUserStats);
    if (statsJson != null) {
      final map = jsonDecode(statsJson) as Map<String, dynamic>;
      map.forEach((k, v) => gs.user.stats[k] = v as int);
    }

    final behaviorJson = prefs.getString('user_behavior');
    if (behaviorJson != null) {
      final map = jsonDecode(behaviorJson) as Map<String, dynamic>;
      map.forEach((k, v) => gs.user.behavior[k] = ActivityMetric.fromJson(v));
    }

    final tasksJson = prefs.getString(_keyTasks);
    if (tasksJson != null) {
      final list = jsonDecode(tasksJson) as List<dynamic>;
      gs.tasks..clear()..addAll(list.map((e) => Task(
        id: e['id'], 
        activityId: e['activityId'], 
        target: e['target'] ?? 1, 
        progress: e['progress'] ?? 0,
        completed: e['completed'] ?? false,
        createdAt: DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime.now(),
      )));
    }

    gs.streak.currentStreak = prefs.getInt(_keyStreak) ?? 0;
    gs.streak.dailyProgressXp = prefs.getInt(_keyDailyXp) ?? 0;
    gs.streak.dailyTasksCompleted = prefs.getInt(_keyDailyTasks) ?? 0;
    final sgJson = prefs.getString(_keyDailyStatGains);
    if (sgJson != null) {
      final map = jsonDecode(sgJson) as Map<String, dynamic>;
      map.forEach((k, v) => gs.streak.dailyStatGains[k] = v as int);
    }
    final dateStr = prefs.getString(_keyLastCompleted);
    gs.streak.lastCompletedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

    gs.streak.streakFreezes = prefs.getInt('streak_freezes') ?? 1;
    final frStr = prefs.getString('last_freeze_reset');
    gs.streak.lastFreezeReset = frStr != null ? DateTime.tryParse(frStr) : null;

    if (gs.streak.lastCompletedDate != null) {
      final last = DateTime(gs.streak.lastCompletedDate!.year, gs.streak.lastCompletedDate!.month, gs.streak.lastCompletedDate!.day);
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (today.difference(last).inDays > 0) {
        gs.streak.dailyProgressXp = 0;
        gs.streak.dailyTasksCompleted = 0;
        gs.streak.dailyStatGains.clear();
      }
    }

    final mDateStr = prefs.getString(_keyMissionDate);
    final mDone = prefs.getBool(_keyMissionCompleted) ?? false;
    final mDate = mDateStr != null ? DateTime.tryParse(mDateStr) : null;
    final sameDay = mDate != null && DateTime(mDate.year, mDate.month, mDate.day).difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays == 0;

    if (sameDay) {
      gs.missions.initDailyMission(
        completedOverride: mDone,
        type: MissionType.values.byName(prefs.getString(_keyMissionType) ?? 'earnXp'),
        target: prefs.getInt(_keyMissionTarget) ?? 50,
        stat: prefs.getString(_keyMissionStat),
        user: gs.user, threshold: gs.dailyXpThreshold, activityTypes: gs.activityTypes,
      );
    } else {
      gs.missions.initDailyMission(user: gs.user, threshold: gs.dailyXpThreshold, activityTypes: gs.activityTypes);
    }

    gs.focus.isFocusMode = prefs.getBool(_keyIsFocus) ?? false;
    gs.focus.focusDuration = prefs.getInt(_keyFocusDuration) ?? 25;
    final fsStr = prefs.getString(_keyFocusStart);
    gs.focus.focusStartTime = fsStr != null ? DateTime.tryParse(fsStr) : null;

    final historyJson = prefs.getString(_keyWorkoutHistory);
    if (historyJson != null) {
      final map = jsonDecode(historyJson) as Map<String, dynamic>;
      gs.workout.history.clear();
      map.forEach((k, v) {
        final list = v as List<dynamic>;
        gs.workout.history[k] = list.map((e) => WorkoutEntry(
          reps: e['reps'] as int?,
          weight: (e['weight'] as num?)?.toDouble(),
          duration: e['duration'] as int?,
          speed: (e['speed'] as num?)?.toDouble(),
          incline: (e['incline'] as num?)?.toDouble(),
          isPR: e['isPR'] ?? false,
        )).toList();
      });
    }

    final achJson = prefs.getString(_keyAchievements);
    if (achJson != null) {
      final list = jsonDecode(achJson) as List<dynamic>;
      for (var item in list) {
        final id = item['id'] as String;
        final a = gs.achievements.firstWhere(
          (e) => e.id == id,
          orElse: () => Achievement(id: '', title: '', description: '', target: 0),
        );
        if (a.id.isNotEmpty) {
          a.progress = item['progress'] ?? 0;
          a.unlocked = item['unlocked'] ?? false;
        }
      }
    }
    
    final hTimeStr = prefs.getString(_keyHealthSyncTime);
    gs.health.lastSyncTime = hTimeStr != null ? DateTime.tryParse(hTimeStr) : null;
    gs.health.lastTotalSteps = prefs.getInt(_keyHealthTotalSteps) ?? 0;
  }

  Future<void> save(GameService gs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserXp, gs.user.xp);
    await prefs.setInt(_keyLifetimeTasks, gs.user.lifetimeTasks);
    await prefs.setInt(_keyLifetimeGymSets, gs.user.lifetimeGymSets);
    await prefs.setString(_keyUserStats, jsonEncode(gs.user.stats));
    await prefs.setString('user_behavior', jsonEncode(gs.user.behavior.map((k, v) => MapEntry(k, v.toJson()))));
    await prefs.setString(_keyTasks, jsonEncode(gs.tasks.map((t) => {
      'id': t.id, 
      'activityId': t.activityId, 
      'target': t.target, 
      'progress': t.progress,
      'completed': t.completed,
      'createdAt': t.createdAt.toIso8601String(),
    }).toList()));
    await prefs.setInt(_keyStreak, gs.streak.currentStreak);
    await prefs.setInt(_keyDailyXp, gs.streak.dailyProgressXp);
    await prefs.setInt(_keyDailyTasks, gs.streak.dailyTasksCompleted);
    await prefs.setString(_keyDailyStatGains, jsonEncode(gs.streak.dailyStatGains));
    if (gs.streak.lastCompletedDate != null) {
      await prefs.setString(_keyLastCompleted, gs.streak.lastCompletedDate!.toIso8601String());
    }
    await prefs.setInt('streak_freezes', gs.streak.streakFreezes);
    if (gs.streak.lastFreezeReset != null) {
      await prefs.setString('last_freeze_reset', gs.streak.lastFreezeReset!.toIso8601String());
    }
    await prefs.setString(_keyMissionDate, DateTime.now().toIso8601String());
    await prefs.setString(_keyMissionType, gs.missions.dailyMission.type.name);
    await prefs.setInt(_keyMissionTarget, gs.missions.dailyMission.target);
    if (gs.missions.dailyMission.stat != null) {
      await prefs.setString(_keyMissionStat, gs.missions.dailyMission.stat!);
    }
    await prefs.setBool(_keyMissionCompleted, gs.missions.dailyMission.completed);
    await prefs.setBool(_keyIsFocus, gs.focus.isFocusMode);
    await prefs.setInt(_keyFocusDuration, gs.focus.focusDuration);
    if (gs.focus.focusStartTime != null) {
      await prefs.setString(_keyFocusStart, gs.focus.focusStartTime!.toIso8601String());
    } else {
      await prefs.remove(_keyFocusStart);
    }

    final historyMap = gs.workout.history.map((k, v) => MapEntry(k, v.map((e) => {
      'reps': e.reps, 'weight': e.weight, 'duration': e.duration, 'speed': e.speed, 'incline': e.incline, 'isPR': e.isPR
    }).toList()));
    await prefs.setString(_keyWorkoutHistory, jsonEncode(historyMap));

    await prefs.setString(_keyAchievements, jsonEncode(gs.achievements.map((a) => a.toJson()).toList()));

    if (gs.health.lastSyncTime != null) {
      await prefs.setString(_keyHealthSyncTime, gs.health.lastSyncTime!.toIso8601String());
    }
    await prefs.setInt(_keyHealthTotalSteps, gs.health.lastTotalSteps);
  }
}
