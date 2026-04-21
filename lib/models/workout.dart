class Exercise {
  final String id;
  final String name;
  final String type; // 'strength' or 'cardio'
  final String? muscleGroup;

  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    this.muscleGroup,
  });
}

class WorkoutEntry {
  final int? reps;
  final double? weight;
  final int? duration; // minutes
  final double? speed;
  final double? incline;
  final int? restSeconds;
  final bool isPR;

  const WorkoutEntry({
    this.reps,
    this.weight,
    this.duration,
    this.speed,
    this.incline,
    this.restSeconds,
    this.isPR = false,
  });
}

class WorkoutSession {
  final String exerciseId;
  final List<WorkoutEntry> entries;

  WorkoutSession({required this.exerciseId, List<WorkoutEntry>? entries})
      : entries = entries ?? [];
}
