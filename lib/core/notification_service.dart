import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(const InitializationSettings(android: android, iOS: ios));
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder(int dailyProgressXp, int dailyXpThreshold, {String? customTitle, String? customBody, int hour = 20}) async {
    await _notifications.cancel(0);
    if (dailyProgressXp >= dailyXpThreshold) return;
    
    final now = DateTime.now();
    var sched = DateTime(now.year, now.month, now.day, hour);
    if (now.isAfter(sched)) sched = sched.add(const Duration(days: 1));
    
    final rem = dailyXpThreshold - dailyProgressXp;
    final title = customTitle ?? 'Habit RPG';
    final body = customBody ?? 'You need $rem more XP to reach your daily goal!';

    await _notifications.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(sched, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily',
          'Daily Reminder',
          channelDescription: 'Reminder to complete daily missions',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Simple Adaptive Notification Strategy
  Future<void> scheduleBehavioralReminders(int streakCount, bool isReturning, int dailyXp, int threshold, {DateTime? lastActive}) async {
    String title = 'Habit RPG';
    String body = 'Ready for today\'s quests?';
    
    // Behavior timing: Delay if recently active
    int reminderHour = 20;
    if (lastActive != null && DateTime.now().difference(lastActive).inHours < 4) {
      reminderHour = 22; 
    }
    
    // Fix #6: Delay if user already made significant progress today
    if (dailyXp > (threshold * 0.5)) {
      reminderHour = (reminderHour + 2).clamp(0, 23);
    }

    if (isReturning) {
      title = 'Welcome Back! ✨';
      body = 'We\'ve simplified your tasks to help you get started again.';
    } else if (streakCount >= 3) {
      title = 'Stay Unstoppable! 🔥';
      body = 'You are on a $streakCount-day streak. Keep it going!';
    }

    await scheduleReminder(dailyXp, threshold, customTitle: title, customBody: body, hour: reminderHour);
  }
}
