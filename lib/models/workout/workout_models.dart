class WorkoutSet {
  int reps;
  double weight;
  bool isCompleted;

  WorkoutSet({
    required this.reps,
    required this.weight,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({int? reps, double? weight, bool? isCompleted}) {
    return WorkoutSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
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
