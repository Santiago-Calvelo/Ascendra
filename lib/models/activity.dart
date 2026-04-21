class ActivityType {
  final String id;
  final String name;
  final String stat;
  final double intensityFactor;

  const ActivityType({
    required this.id,
    required this.name,
    required this.stat,
    this.intensityFactor = 1.0,
  });
}

class Activity {
  final String id;
  final String name;
  final String typeId;
  final int xpPerUnit;

  const Activity({
    required this.id,
    required this.name,
    required this.typeId,
    required this.xpPerUnit,
  });
}

/// Represents a single record from Health APIs (Health Connect / Google Fit)
class HealthRecord {
  final DateTime startTime;
  final DateTime endTime;
  final int value;
  final String? id; // Optional unique identifier from the API

  HealthRecord({
    required this.startTime,
    required this.endTime,
    required this.value,
    this.id,
  });

  Duration get duration => endTime.difference(startTime);
  
  /// Steps per minute for this specific record
  double get stepsPerMinute => duration.inMinutes > 0 
    ? value / duration.inMinutes 
    : value.toDouble(); // Fallback for < 1 min windows

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'value': value,
    'id': id,
  };
}
