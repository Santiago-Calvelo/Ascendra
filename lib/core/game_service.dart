import '../models/activity.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/workout.dart';
import 'streak_service.dart';
import 'mission_service.dart';
import 'focus_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'workout_service.dart';
import '../models/achievement.dart';
import 'social_service.dart';
import 'health_service.dart';

class GameService {
  final User user = User();
  final StreakService streak = StreakService();
  final MissionService missions = MissionService();
  final FocusService focus = FocusService();
  final WorkoutService workout = WorkoutService();
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  late final HealthService health;
  late final SocialService social;

  GameService() {
    health = HealthService(this);
    social = SocialService(this);
    social.init();
  }

  final List<Achievement> achievements = [
    Achievement(id: 'tasks_10', title: 'Novice Adventurer', description: 'Complete 10 tasks (+5% XP)', target: 10, rewardType: RewardType.xpMultiplier, rewardValue: 0.05),
    Achievement(id: 'tasks_50', title: 'Master of Habits', description: 'Complete 50 tasks (+10% XP)', target: 50, rewardType: RewardType.xpMultiplier, rewardValue: 0.10),
    Achievement(id: 'gym_10', title: 'Iron Initiate', description: 'Perform 10 gym sets (+1 Stat)', target: 10, rewardType: RewardType.statBonus, rewardValue: 1),
    Achievement(id: 'streak_7', title: 'Consistent Hero', description: 'Reach a 7 day streak (+10% XP)', target: 7, rewardType: RewardType.xpMultiplier, rewardValue: 0.10),
    Achievement(id: 'str_10', title: 'Mighty Warrior', description: 'Reach 10 Strength (+2 Stat)', target: 10, rewardType: RewardType.statBonus, rewardValue: 2),
  ];

  double get xpMultiplier => 1.0 + achievements.where((a) => a.unlocked && a.rewardType == RewardType.xpMultiplier).fold(0.0, (sum, a) => sum + a.rewardValue);
  int get statBonus => achievements.where((a) => a.unlocked && a.rewardType == RewardType.statBonus).fold(0, (sum, a) => sum + a.rewardValue.toInt());


  Function(Achievement)? onAchievementUnlocked;
  Function(String)? onMilestone;

  // Public API proxies
  int get currentStreak => streak.currentStreak;
  int get dailyProgressXp => streak.dailyProgressXp;
  int get dailyTasksCompleted => streak.dailyTasksCompleted;
  Map<String, int> get dailyStatGains => streak.dailyStatGains;
  Mission get dailyMission => missions.dailyMission;
  bool get isFocusMode => focus.isFocusMode;
  int get focusDuration => focus.focusDuration;
  DateTime? get focusStartTime => focus.focusStartTime;

  int get dailyXpThreshold => 50 + (user.level * 5);

  final List<ActivityType> activityTypes = const [
    ActivityType(id: 'cardio', name: 'Cardio', stat: 'resistencia', intensityFactor: 1.0),
    ActivityType(id: 'gym',    name: 'Gym',    stat: 'fuerza',      intensityFactor: 1.3),
    ActivityType(id: 'focus',  name: 'Focus',  stat: 'disciplina',  intensityFactor: 0.8),
  ];

  final List<Task> tasks = [];

  Future<void> load() async {
    await _notifications.init();
    await _storage.load(this);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Hardened Daily Reset Logic
    if (tasks.isNotEmpty) {
      final taskDate = DateTime(tasks.first.createdAt.year, tasks.first.createdAt.month, tasks.first.createdAt.day);
      if (taskDate.isBefore(today)) {
        generateDailyTasks();
      }
    } else {
      generateDailyTasks();
    }
    
    _notifications.scheduleBehavioralReminders(
      streak.currentStreak, 
      streak.isReturning, 
      streak.dailyProgressXp, 
      dailyXpThreshold,
      lastActive: user.lastActiveTime,
    );
    
    syncHealth();
  }

  Future<void> syncHealth() => health.syncData();

  void generateDailyTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 1. Daily Reset (Fix #2: Reset daily XP)
    if (tasks.isNotEmpty) {
      final lastDate = DateTime(tasks.first.createdAt.year, tasks.first.createdAt.month, tasks.first.createdAt.day);
      if (lastDate.isBefore(today)) {
        user.dailyXp = 0; // Reset daily progress
        for (final t in tasks) {
          if (!t.completed) user.getMetric(t.activityId).updatePerformance(false);
        }
        tasks.clear();
      } else {
        return; 
      }
    }
    
    // 2. The 3-Zone Selection Engine (Final Consistency)
    final templates = [
      {'id': 'cardio_steps', 'base': 3000, 'step': 500, 'min': 1000},
      {'id': 'gym_routine',  'base': 2,    'step': 1,   'min': 1},
      {'id': 'cardio_time',  'base': 15,   'step': 5,   'min': 10},
      {'id': 'focus',         'base': 20,   'step': 10,  'min': 5},
    ];

    double retentionMod = 1.0;
    if (streak.currentStreak == 0 && streak.lastCompletedDate != null) {
      retentionMod = 0.5; 
      onMilestone?.call('Welcome back! Tasks are 50% easier today. ⚡');
    }

    templates.sort((a, b) => 
      user.getMetric(a['id'] as String).multiplier.compareTo(user.getMetric(b['id'] as String).multiplier));

    // Fix #1: Strictly 3 tasks (Comfort, Growth, Normal)
    _addZoneTask(templates[0], 'comfort', 0.6 * retentionMod, now);
    _addZoneTask(templates[3], 'growth', 1.4 * retentionMod, now);
    _addZoneTask(templates[1], 'normal', 1.0 * retentionMod, now);

    save();
  }

  void _addZoneTask(Map<String, dynamic> template, String zone, double zoneMod, DateTime now) {
    final aid = template['id'] as String;
    if (tasks.any((t) => t.activityId == aid)) return;

    final metric = user.getMetric(aid);
    final base = (template['base'] as int) + ((template['step'] as int) * (user.level / 2)).round();
    
    // Fix #7: Apply minimum targets after calculation
    int target = (base * metric.multiplier * zoneMod).round();
    final min = template['min'] as int;
    if (target < min) target = min;
    
    tasks.add(Task(
      id: 'dt_${aid}_${now.millisecondsSinceEpoch}',
      activityId: aid,
      createdAt: now,
      target: target,
      zone: zone,
    ));
  }

  Future<void> save() async {
    await _storage.save(this);
  }

  String getTaskName(Task t) {
    String name = 'Quest';
    if (t.activityId == 'cardio_steps') name = 'Walk ${t.target} steps';
    if (t.activityId == 'cardio_time')  name = 'Cardio for ${t.target} mins';
    if (t.activityId == 'gym_routine')  name = 'Gym Routine (${t.progress}/${t.target})';
    if (t.activityId == 'focus')         name = 'Focus (${t.target} mins)';

    if (t.zone == 'comfort') return '[$name] (Quick Win! ⚡)';
    if (t.zone == 'growth')  return '[$name] (Pushing Limits! 🔥)';
    return name;
  }

  int xpFor(Task t) {
    double base = 20;
    if (t.activityId == 'cardio_steps') base = t.target * 0.01;
    if (t.activityId == 'cardio_time')  base = t.target * 3.0;
    if (t.activityId == 'gym_routine')  base = t.target * 50.0;
    if (t.activityId == 'focus')         base = t.target * 4.0;
    
    return (base * xpMultiplier).round();
  }

  int statGainFor(Task t) {
    int base = 1;
    if (t.activityId.startsWith('cardio')) base = (t.target / 1000).ceil(); 
    if (t.activityId == 'cardio_time')  base = (t.target / 15).ceil();
    if (t.activityId == 'gym_routine')  base = (t.target / 2).ceil();
    if (t.activityId == 'focus')         base = (t.target / 20).ceil();
    
    return (base + statBonus).clamp(1, 100);
  }

  int get xpToNextLevel => (user.level * user.level * 100) - user.xp;
  double get levelProgress {
    final prev = (user.level - 1) * (user.level - 1) * 100;
    final next = user.level * user.level * 100;
    return ((user.xp - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  Future<void> toggleTask(Task task) async {
    if (!task.completed) {
      task.progress = task.target;
      await _finalizeTask(task);
    } else {
      await _finalizeTask(task, reversing: true);
    }
  }

  final Map<String, DateTime> _lastReportTimes = {};

  void reportActivity(String activityId, int value) {
    if (value <= 0) return;

    // Fix #5: Consistent Activity Update
    user.lastActiveTime = DateTime.now();

    // Fix #2: Lightweight Anti-Spam
    int validatedValue = value;
    final now = DateTime.now();
    final lastReport = _lastReportTimes[activityId];
    if (lastReport != null && now.difference(lastReport).inSeconds < 2) {
      validatedValue = (value * 0.5).round(); // Reduced value for spamming
    }
    _lastReportTimes[activityId] = now;

    // Standard capping logic
    if (activityId == 'cardio_steps') validatedValue = validatedValue.clamp(0, 1000);
    if (activityId == 'cardio_time')  validatedValue = validatedValue.clamp(0, 60);
    if (activityId == 'gym_routine')  validatedValue = validatedValue.clamp(0, 5);
    if (activityId == 'focus')         validatedValue = validatedValue.clamp(0, 45);

    final activeTasks = tasks.where((t) => t.activityId == activityId && !t.completed);
    for (final task in activeTasks) {
      task.progress = (task.progress + validatedValue).clamp(0, task.target);
      if (task.percent >= 1.0) _finalizeTask(task);
    }
    save();
  }

  String _getStatForActivity(String aid) {
    // Resolve group from activityId (e.g., cardio_steps -> cardio)
    final groupId = aid.contains('_') ? aid.substring(0, aid.indexOf('_')) : aid;
    
    // Find corresponding ActivityType in the central registry
    try {
      return activityTypes.firstWhere((t) => t.id == groupId).stat;
    } catch (_) {
      return 'disciplina'; // Safe fallback
    }
  }

  Future<void> _finalizeTask(Task task, {bool reversing = false}) async {
    if (!reversing && task.completed) return;
    if (reversing && !task.completed) return;
    
    final xp = xpFor(task);
    final statGain = statGainFor(task);
    final stat = _getStatForActivity(task.activityId);

    final oldLevel = user.level;
    final oldStats = Map<String, int>.from(user.stats);

    if (!reversing) {
      task.completed = true;
      user.getMetric(task.activityId).updatePerformance(true);
      user.addXP(xp);
      streak.dailyProgressXp += xp; // UNIFY: Keep daily progress aligned
      user.incrementStat(stat, statGain);
      user.lifetimeTasks++;
      streak.dailyTasksCompleted++;
      streak.dailyStatGains[stat] = (streak.dailyStatGains[stat] ?? 0) + statGain;
      
      social.onActivity('tasks', 1);
      social.onActivity('xp', xp);
    } else {
      task.completed = false;
      task.progress = 0;
      user.removeXP(xp);
      user.decrementStat(stat, statGain);
      streak.dailyTasksCompleted = (streak.dailyTasksCompleted - 1).clamp(0, 999);
      streak.dailyProgressXp = (streak.dailyProgressXp - xp).clamp(0, 999999);
      streak.dailyStatGains[stat] = ((streak.dailyStatGains[stat] ?? 0) - statGain).clamp(0, 999999);
    }

    if (!reversing) {
      _checkMilestones(oldLevel, oldStats);
      streak.updateStreak(xp, user, dailyXpThreshold);
      missions.checkMission(user, streak.dailyProgressXp, streak.dailyTasksCompleted, streak.dailyStatGains);
      _checkAchievements();
    }
    
    await save();
    _notifications.scheduleBehavioralReminders(
      streak.currentStreak, 
      streak.isReturning, 
      streak.dailyProgressXp, 
      dailyXpThreshold,
    );
  }

  Map<String, int> addWorkoutEntry(String exerciseId, WorkoutEntry entry) {
    final ex = workout.exercises.firstWhere((e) => e.id == exerciseId);
    final typeId = ex.type == 'strength' ? 'gym' : 'cardio';
    final type = activityTypes.firstWhere((t) => t.id == typeId);
    
    workout.history.putIfAbsent(exerciseId, () => []).add(entry);
    
    // Fix #5: Update lastActiveTime in workout path
    user.lastActiveTime = DateTime.now();
    
    if (ex.type == 'strength') {
      reportActivity('gym_routine', 1);
    } else {
      reportActivity('cardio_steps', (entry.duration ?? 0) * 100); // Conversion
    }
    
    save();
    return {'xp': 0, 'statGain': 0}; // Rewards are now handled via tasks
  }

  void startFocus(int mins) { focus.start(mins); save(); }
  bool completeFocus() {
    final focusType = activityTypes.firstWhere((t) => t.id == 'focus');
    final res = focus.complete(
      user: user,
      intensityFactor: focusType.intensityFactor,
      onXpReward: (reward) {
        // We report progress, the task completion awards the XP
        reportActivity('focus', focus.focusDuration);
      },
      onCancel: cancelFocus,
    );
    if (res) {
      save();
    }
    return res;
  }
  void cancelFocus() { focus.cancel(); save(); }

  Future<void> addTask(String aid, {int target = 1}) async {
    tasks.add(Task(id: DateTime.now().millisecondsSinceEpoch.toString(), activityId: aid, target: target));
    await save();
  }

  void _checkAchievements() {
    for (var a in achievements) {
      if (a.unlocked) continue;
      if (a.id == 'tasks_10' || a.id == 'tasks_50') a.progress = user.lifetimeTasks;
      if (a.id == 'gym_10') a.progress = user.lifetimeGymSets;
      if (a.id == 'streak_7') a.progress = streak.currentStreak;
      if (a.id == 'str_10') a.progress = user.stats['fuerza'] ?? 0;

      if (a.progress >= a.target) {
        a.unlocked = true;
        user.addXP(50);
        onAchievementUnlocked?.call(a);
      }
    }
  }

  void _checkMilestones(int oldLevel, Map<String, int> oldStats) {
    String? msg;
    final highestLvl = [20, 10, 5].firstWhere((m) => user.level >= m && oldLevel < m, orElse: () => 0);
    if (highestLvl > 0) {
      user.addXP(20);
      msg = 'ASCENSION! Level $highestLvl';
    }

    user.stats.forEach((k, v) {
      final ov = oldStats[k] ?? 0;
      final highestStat = [50, 20, 10].firstWhere((m) => v >= m && ov < m, orElse: () => 0);
      if (highestStat > 0) {
        user.addXP(20);
        msg = (msg == null) ? 'BREAKTHROUGH! $k is now $highestStat' : '$msg & $k UP!';
      }
    });
    
    if (msg != null) onMilestone?.call(msg);
  }
}
