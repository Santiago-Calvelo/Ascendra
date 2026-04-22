import 'package:flutter/material.dart';
import '../../../models/workout/workout_models.dart';
import '../../theme/game_theme.dart';

class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({super.key});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  final List<Exercise> _exercises = [];

  void _addExercise() {
    setState(() {
      _exercises.add(
        Exercise(
          id: DateTime.now().toString(),
          name: 'Bench Press',
          category: 'strength',
          sets: [WorkoutSet(reps: 10, weight: 60)],
          restSeconds: 90,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROUTINE BUILDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: GameTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {}, // Save routine
            icon: const Icon(Icons.save, color: GameTheme.accent),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == _exercises.length) {
            return _buildAddExerciseButton();
          }
          return ExerciseBuilderCard(
            exercise: _exercises[index],
            onRemove: () => setState(() => _exercises.removeAt(index)),
          );
        },
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return GestureDetector(
      onTap: _addExercise,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: GameTheme.cardBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameTheme.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: GameTheme.primary),
            SizedBox(width: 8),
            Text('ADD EXERCISE', style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class ExerciseBuilderCard extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onRemove;

  const ExerciseBuilderCard({super.key, required this.exercise, required this.onRemove});

  @override
  State<ExerciseBuilderCard> createState() => _ExerciseBuilderCardState();
}

class _ExerciseBuilderCardState extends State<ExerciseBuilderCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GameTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameTheme.border),
      ),
      child: Column(
        children: [
          // Header
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            leading: const Icon(Icons.fitness_center, color: GameTheme.mutedForeground),
            title: Text(widget.exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${widget.exercise.sets.length} SETS • ${widget.exercise.restSeconds}s REST', style: const TextStyle(fontSize: 12, color: GameTheme.mutedForeground)),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: GameTheme.mutedForeground),
          ),
          
          if (_isExpanded) ...[
            const Divider(color: GameTheme.border, height: 1),
            // Sets Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text('SET', style: TextStyle(fontSize: 10, color: GameTheme.mutedForeground))),
                  Expanded(child: Text('REPS', style: TextStyle(fontSize: 10, color: GameTheme.mutedForeground))),
                  Expanded(child: Text('WEIGHT (KG)', style: TextStyle(fontSize: 10, color: GameTheme.mutedForeground))),
                  SizedBox(width: 40),
                ],
              ),
            ),
            // Sets List
            ...List.generate(widget.exercise.sets.length, (index) {
              final set = widget.exercise.sets[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: _buildInlineEditor(set.reps.toString())),
                    Expanded(child: _buildInlineEditor(set.weight.toString())),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                      onPressed: () => setState(() => widget.exercise.sets.removeAt(index)),
                    ),
                  ],
                ),
              );
            }),
            // Action Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    label: const Text('REMOVE', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => widget.exercise.sets.add(WorkoutSet(reps: 10, weight: 60))),
                    icon: const Icon(Icons.add, size: 18, color: GameTheme.primary),
                    label: const Text('ADD SET', style: TextStyle(color: GameTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineEditor(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: GameTheme.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}
