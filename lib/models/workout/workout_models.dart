enum SetStatus { idle, active, resting, completed }

class WorkoutSet {
  int reps;
  double weight;
  SetStatus status;

  WorkoutSet({
    required this.reps,
    required this.weight,
    this.status = SetStatus.idle,
  });

  bool get isCompleted => status == SetStatus.completed;

  WorkoutSet copyWith({int? reps, double? weight, SetStatus? status}) {
    return WorkoutSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      status: status ?? this.status,
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final String category; // e.g., 'strength', 'hypertrophy'
  final List<WorkoutSet> sets;
  int restSeconds;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.sets,
    this.restSeconds = 60,
  });
}

class Routine {
  final String id;
  String name;
  final List<Exercise> exercises;

  Routine({
    required this.id,
    required this.name,
    required this.exercises,
  });
}
