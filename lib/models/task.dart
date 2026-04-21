class Task {
  final String id;
  final String activityId;
  final int target;
  final DateTime createdAt;
  int progress;
  bool completed;
  final String? zone; // 'comfort', 'normal', 'growth'

  Task({
    required this.id,
    required this.activityId,
    required this.createdAt,
    this.target = 1,
    this.progress = 0,
    this.completed = false,
    this.zone,
  });

  double get percent => (progress / target).clamp(0.0, 1.0);
}
