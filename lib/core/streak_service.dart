import '../models/user.dart';

class StreakService {
  int currentStreak = 0;
  int dailyProgressXp = 0;
  int dailyTasksCompleted = 0;
  final Map<String, int> dailyStatGains = {};
  DateTime? lastCompletedDate;
  int streakFreezes = 1;
  DateTime? lastFreezeReset;

  /// Essential Momentum: Are we in a streak or starting over?
  bool get isReturning => currentStreak == 0 && lastCompletedDate != null;

  int get inactivityDays {
    if (lastCompletedDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastCompletedDate!.year, lastCompletedDate!.month, lastCompletedDate!.day);
    return today.difference(last).inDays;
  }

  void updateStreak(int earnedXp, User user, int threshold) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final previousDate = lastCompletedDate == null
        ? null
        : DateTime(
            lastCompletedDate!.year,
            lastCompletedDate!.month,
            lastCompletedDate!.day);

    if (previousDate != null && todayDate.difference(previousDate).inDays > 0) {
      dailyProgressXp = 0;
      dailyTasksCompleted = 0;
      dailyStatGains.clear();
    }

    dailyProgressXp += earnedXp;
    lastCompletedDate = today;

    if (dailyProgressXp >= threshold) {
      if (previousDate == null) {
        currentStreak = 1;
      } else {
        final diff = todayDate.difference(previousDate).inDays;
        if (diff <= 1) {
          currentStreak++;
        } else {
          currentStreak = 1; // Reset if gap > 1 day
        }
      }
    }
  }
}
