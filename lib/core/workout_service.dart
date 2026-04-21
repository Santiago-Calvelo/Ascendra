import '../models/workout.dart';

class WorkoutService {
  final List<Exercise> exercises = const [
    Exercise(id: 'press_banca', name: 'Press de Banca', type: 'strength', muscleGroup: 'Pecho'),
    Exercise(id: 'sentadilla',  name: 'Sentadilla',     type: 'strength', muscleGroup: 'Piernas'),
    Exercise(id: 'cinta',       name: 'Cinta',          type: 'cardio'),
  ];
  final Map<String, List<WorkoutEntry>> history = {};

  int calculateXP(WorkoutEntry entry, String type, double factor) {
    if (type == 'strength') {
      return ((entry.weight ?? 0) * (entry.reps ?? 0) * 0.08 * factor).round();
    } else {
      final speed = entry.speed ?? 0;
      final duration = entry.duration ?? 0;
      final incline = entry.incline ?? 0;
      return (duration * speed * (1 + incline / 10) * 0.05 * factor).round();
    }
  }

  bool checkPR(String id, WorkoutEntry entry, String type) {
    final list = history[id] ?? [];
    if (list.isEmpty) return true;
    final score = _score(entry, type);
    return score > list.map((e) => _score(e, type)).reduce((a, b) => a > b ? a : b);
  }

  double _score(WorkoutEntry e, String type) => type == 'strength' 
    ? (e.weight ?? 0) * (e.reps ?? 0) 
    : (e.duration ?? 0) * (e.speed ?? 0);
}
