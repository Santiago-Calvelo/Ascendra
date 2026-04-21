import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/workout/workout_models.dart';
import '../../theme/game_theme.dart';

enum EditingField { none, reps, weight }

class WorkoutExecutionScreen extends StatefulWidget {
  final Routine routine;
  final GameService gameService;

  const WorkoutExecutionScreen({super.key, required this.routine, required this.gameService});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _FloatingXp {
  final int id;
  int value;
  final Offset position;
  final double drift;
  _FloatingXp(this.id, this.value, this.position, this.drift);
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> with TickerProviderStateMixin {
  int _currentExerciseIndex = 0;
  DateTime? _restEndTime;
  bool _workoutComplete = false;
  Ticker? _ticker;
  Timer? _advanceTimer;
  final List<_FloatingXp> _floatingXps = [];
  int _xpIdCounter = 0;
  DateTime _lastXpTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Progress bar animation
  late AnimationController _progressPulseController;

  static const String _keyRestEndTime = 'active_workout_rest_end';
  static const String _keyExerciseIndex = 'active_workout_exercise_index';
  static const String _keySetsState = 'active_workout_sets_state';

  @override
  void initState() {
    super.initState();
    _progressPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    // Use Ticker for high-performance UI refresh
    _ticker = createTicker((_) {
      if (_restEndTime != null) {
        if (DateTime.now().isAfter(_restEndTime!)) {
          _stopRest(); // Deterministic completion
        } else {
          setState(() {}); 
        }
      }
    });
    _restoreState();
  }

  void _showFloatingXp(int value, Offset position) {
    final now = DateTime.now();
    setState(() {
      // Logic for merging rapid XP popups
      if (_floatingXps.isNotEmpty && now.difference(_lastXpTime) < const Duration(milliseconds: 400)) {
        _floatingXps.last.value += value;
      } else {
        _floatingXps.add(_FloatingXp(
          _xpIdCounter++,
          value,
          position,
          (Random().nextDouble() - 0.5) * 40, // Random drift
        ));
      }
      _lastXpTime = now;
      
      // Pulse the progress bar
      _progressPulseController.forward(from: 0);
    });
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Restore Exercise Index
    final savedIndex = prefs.getInt(_keyExerciseIndex);
    if (savedIndex != null && savedIndex < widget.routine.exercises.length) {
      if (mounted) setState(() => _currentExerciseIndex = savedIndex);
    }

    // Restore Set Completion States
    final setsJson = prefs.getString(_keySetsState);
    if (setsJson != null) {
      try {
        final List<dynamic> data = jsonDecode(setsJson);
        for (int i = 0; i < data.length && i < widget.routine.exercises.length; i++) {
          final List<dynamic> exerciseSets = data[i];
          for (int j = 0; j < exerciseSets.length && j < widget.routine.exercises[i].sets.length; j++) {
            widget.routine.exercises[i].sets[j].isCompleted = exerciseSets[j] as bool;
          }
        }
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Failed to restore sets state: $e');
      }
    }

    // Restore Rest Timer
    final restStr = prefs.getString(_keyRestEndTime);
    if (restStr != null) {
      final endTime = DateTime.tryParse(restStr);
      if (endTime != null && endTime.isAfter(DateTime.now())) {
        if (mounted) {
          setState(() => _restEndTime = endTime);
          _ticker?.start(); // Only start ticker if rest is active
        }
      } else {
        unawaited(prefs.remove(_keyRestEndTime));
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyExerciseIndex, _currentExerciseIndex);
    
    final setsData = widget.routine.exercises.map((e) => e.sets.map((s) => s.isCompleted).toList()).toList();
    await prefs.setString(_keySetsState, jsonEncode(setsData));
    
    if (_restEndTime != null) {
      await prefs.setString(_keyRestEndTime, _restEndTime!.toIso8601String());
    } else {
      await prefs.remove(_keyRestEndTime);
    }
  }

  Future<void> _startRest(int seconds) async {
    HapticFeedback.mediumImpact();
    final endTime = DateTime.now().add(Duration(seconds: seconds));
    
    if (mounted) {
      setState(() {
        _restEndTime = endTime;
        if (_ticker != null && !_ticker!.isActive) _ticker!.start();
      });
    }
    
    unawaited(_saveState());
  }

  Future<void> _stopRest() async {
    if (mounted) {
      setState(() {
        _restEndTime = null;
        if (_ticker != null && _ticker!.isActive) _ticker!.stop();
      });
    }
    unawaited(_saveState());
  }

  void _completeSet(WorkoutSet set, Exercise exercise, Offset tapPosition) {
    if (set.isCompleted || _workoutComplete) return;
    
    if (mounted) {
      setState(() => set.isCompleted = true);
    }

    // Connect to GameService: Report Activity per Set
    final int value = set.reps;
    widget.gameService.reportActivity('gym_routine', value);
    
    // UI Feedback: Show floating XP at tap position
    _showFloatingXp(value, tapPosition);
    HapticFeedback.heavyImpact();

    _startRest(exercise.restSeconds);

    if (exercise.sets.every((s) => s.isCompleted)) {
      _scheduleAutoAdvance();
    }
    unawaited(_saveState());
  }

  void _scheduleAutoAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentExerciseIndex < widget.routine.exercises.length - 1) {
        setState(() => _currentExerciseIndex++);
        unawaited(_saveState());
      } else {
        setState(() => _workoutComplete = true);
        widget.gameService.reportActivity('gym_session', 1); 
        unawaited(_clearPersistence());
      }
    });
  }

  Future<void> _clearPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyExerciseIndex);
    await prefs.remove(_keySetsState);
    await prefs.remove(_keyRestEndTime);
  }

  int get _remainingRestSeconds {
    if (_restEndTime == null) return 0;
    final diff = _restEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_workoutComplete) return _buildWorkoutComplete();

    final currentExercise = widget.routine.exercises[_currentExerciseIndex];

    return Scaffold(
      backgroundColor: GameTheme.background,
      appBar: AppBar(
        title: Text(widget.routine.name.toUpperCase(), style: const TextStyle(fontSize: 14, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildOverallProgress(),
              
              // Exercise Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'CURRENT EXERCISE',
                      style: TextStyle(color: GameTheme.primary.withOpacity(0.7), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentExercise.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: GameTheme.foreground),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Sets List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: currentExercise.sets.length,
                  itemBuilder: (context, index) {
                    final set = currentExercise.sets[index];
                    // Highlight the next incomplete set
                    final isNextTarget = !set.isCompleted && 
                        (index == 0 || currentExercise.sets[index - 1].isCompleted);

                    return ActiveSetRow(
                      set: set,
                      index: index,
                      isNextTarget: isNextTarget,
                      onTap: () => _completeSet(set, currentExercise),
                    );
                  },
                ),
              ),

              _buildBottomNavigation(),
            ],
          ),

          // Rest Overlay with entrance animation logic
          if (_remainingRestSeconds > 0)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: RestTimerWidget(
                  seconds: _remainingRestSeconds,
                  onSkip: _stopRest,
                ),
              ),
            ),

          // Floating XPs
          ..._floatingXps.map((xp) => FloatingXpText(
            key: ValueKey(xp.id),
            value: xp.value,
            onComplete: () => setState(() => _floatingXps.removeWhere((e) => e.id == xp.id)),
          )),
        ],
      ),
    );
  }

  Widget _buildWorkoutComplete() {
    return Scaffold(
      backgroundColor: GameTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, color: GameTheme.accent, size: 80),
            const SizedBox(height: 24),
            const Text('WORKOUT COMPLETE!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Your progress has been recorded.', style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GameTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('BACK TO BASE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    final totalSets = widget.routine.exercises.expand((e) => e.sets).length;
    if (totalSets == 0) return const SizedBox.shrink();
    
    final completedSets = widget.routine.exercises.expand((e) => e.sets).where((s) => s.isCompleted).length;
    final progress = (completedSets / totalSets).clamp(0.0, 1.0);

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _progressPulseController, curve: Curves.elasticOut)),
      child: Container(
        height: 6,
        width: double.infinity,
        decoration: BoxDecoration(
          color: GameTheme.border,
          boxShadow: [
            BoxShadow(
              color: GameTheme.accent.withOpacity(_progressPulseController.value * 0.5),
              blurRadius: 10 * _progressPulseController.value,
              spreadRadius: 2 * _progressPulseController.value,
            )
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(color: GameTheme.accent),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentExerciseIndex > 0 ? () {
              setState(() => _currentExerciseIndex--);
              unawaited(_saveState());
            } : null,
            icon: const Icon(Icons.arrow_back_ios, color: GameTheme.mutedForeground, size: 18),
          ),
          Text(
            'EXERCISE ${_currentExerciseIndex + 1} OF ${widget.routine.exercises.length}',
            style: const TextStyle(color: GameTheme.mutedForeground, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          IconButton(
            onPressed: _currentExerciseIndex < widget.routine.exercises.length - 1 
              ? () {
                setState(() => _currentExerciseIndex++);
                unawaited(_saveState());
              } : null,
            icon: const Icon(Icons.arrow_forward_ios, color: GameTheme.mutedForeground, size: 18),
          ),
        ],
      ),
    );
  }
}

class ActiveSetRow extends StatefulWidget {
  final WorkoutSet set;
  final int index;
  final bool isNextTarget;
  final Function(Offset position) onTap;

  const ActiveSetRow({
    super.key, 
    required this.set, 
    required this.index, 
    required this.isNextTarget,
    required this.onTap
  });

  @override
  State<ActiveSetRow> createState() => _ActiveSetRowState();
}

class _ActiveSetRowState extends State<ActiveSetRow> {
  EditingField _editingField = EditingField.none;
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.set.reps.toString());
    _weightController = TextEditingController(text: widget.set.weight.toString());
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _save(EditingField field) {
    if (!mounted) return;
    setState(() {
      if (field == EditingField.reps) {
        widget.set.reps = int.tryParse(_repsController.text) ?? widget.set.reps;
      } else if (field == EditingField.weight) {
        widget.set.weight = double.tryParse(_weightController.text) ?? widget.set.weight;
      }
      _editingField = EditingField.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.set.isCompleted;

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: widget.isNextTarget ? 1.02 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCompleted ? GameTheme.primary.withOpacity(0.05) : GameTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted 
                ? GameTheme.primary.withOpacity(0.5) 
                : (widget.isNextTarget ? GameTheme.primary.withOpacity(0.8) : GameTheme.border),
            width: widget.isNextTarget ? 1.5 : 1,
          ),
          boxShadow: widget.isNextTarget ? [
            BoxShadow(color: GameTheme.primary.withOpacity(0.1), blurRadius: 10, spreadRadius: 0)
          ] : null,
        ),
        child: Row(
          children: [
            // Set Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? GameTheme.primary : GameTheme.background,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : GameTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Editable Stats
            Expanded(
              child: Row(
                children: [
                  _buildEditableStat(
                    label: 'REPS',
                    value: _repsController.text,
                    field: EditingField.reps,
                    controller: _repsController,
                    isCompleted: isCompleted,
                  ),
                  const SizedBox(width: 20),
                  _buildEditableStat(
                    label: 'WEIGHT',
                    value: _weightController.text,
                    field: EditingField.weight,
                    controller: _weightController,
                    suffix: 'KG',
                    isCompleted: isCompleted,
                  ),
                ],
              ),
            ),

            // Completion Button
            _buildCompletionButton(isCompleted, context),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableStat({
    required String label,
    required String value,
    required EditingField field,
    required TextEditingController controller,
    required bool isCompleted,
    String? suffix,
  }) {
    final isEditing = _editingField == field;

    return Expanded(
      child: GestureDetector(
        onTap: isCompleted ? null : () => setState(() => _editingField = field),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: GameTheme.mutedForeground, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 2),
            if (isEditing)
              SizedBox(
                height: 32,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GameTheme.accent),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _save(field),
                  onTapOutside: (_) => _save(field),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? GameTheme.primary.withOpacity(0.7) : GameTheme.foreground,
                    ),
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: 2),
                    Text(suffix, style: TextStyle(fontSize: 10, color: GameTheme.mutedForeground.withOpacity(0.5))),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionButton(bool isCompleted, BuildContext context) {
    return Builder(
      builder: (btnContext) {
        return GestureDetector(
          onTapDown: isCompleted ? null : (details) {
            final RenderBox box = btnContext.findRenderObject() as RenderBox;
            final position = box.localToGlobal(Offset.zero);
            // Pass the top-left of the button as the origin for the XP
            widget.onTap(position);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.transparent : GameTheme.primary,
              borderRadius: BorderRadius.circular(12),
              border: isCompleted ? Border.all(color: GameTheme.primary.withOpacity(0.3)) : null,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.flash_on,
              color: isCompleted ? GameTheme.primary : Colors.white,
              size: 24,
            ),
          ),
        );
      }
    );
  }
}

class RestTimerWidget extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;

  const RestTimerWidget({super.key, required this.seconds, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: GameTheme.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: GameTheme.accent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: GameTheme.background, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('REST TIME', style: TextStyle(color: GameTheme.background, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                Text(
                  '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: GameTheme.background, fontSize: 24, fontWeight: FontWeight.bold, tabularNums: true),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSkip,
            child: const Text('SKIP', style: TextStyle(color: GameTheme.background, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class FloatingXpText extends StatefulWidget {
  final _FloatingXp xp;
  final VoidCallback onComplete;

  const FloatingXpText({super.key, required this.xp, required this.onComplete});

  @override
  State<FloatingXpText> createState() => _FloatingXpTextState();
}

class _FloatingXpTextState extends State<FloatingXpText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _translateY = Tween<double>(begin: 0, end: -120).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.3), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 75),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.xp.position.dx + widget.xp.drift,
      top: widget.xp.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _translateY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GameTheme.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: GameTheme.accent.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                  child: Text(
                    '+${widget.xp.value} XP',
                    style: const TextStyle(color: GameTheme.background, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
