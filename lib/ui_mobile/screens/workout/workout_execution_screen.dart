import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/workout/workout_models.dart';
import '../../../core/game_service.dart';
import '../../theme/game_theme.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final Routine routine;
  final GameService gameService;

  const WorkoutExecutionScreen({super.key, required this.routine, required this.gameService});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class FloatingXp {
  final int id;
  int value;
  final Offset position;
  final double drift;
  FloatingXp(this.id, this.value, this.position, this.drift);
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> with TickerProviderStateMixin {
  int _currentExerciseIndex = 0;
  DateTime? _restEndTime;
  bool _workoutComplete = false;
  Ticker? _ticker;
  Timer? _advanceTimer;
  final List<FloatingXp> _floatingXps = [];
  int _xpIdCounter = 0;
  DateTime _lastXpTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Progress bar animation
  late AnimationController _progressPulseController;

  static const String _keyRestEndTime = 'active_workout_rest_end';
  static const String _keyExerciseIndex = 'active_workout_exercise_index';
  static const String _keySetsState = 'active_workout_sets_state';
  
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _progressPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _ticker = createTicker((_) {
      if (_restEndTime != null) {
        if (DateTime.now().isAfter(_restEndTime!)) {
          _stopRest();
        } else {
          setState(() {}); 
        }
      }
    });
    _restoreState();
  }

  void _showFloatingXp(int value, Offset position) {
    final now = DateTime.now();
    final bool shouldMerge = _floatingXps.isNotEmpty && now.difference(_lastXpTime) < const Duration(milliseconds: 400);
    _lastXpTime = now;
    
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      setState(() {
        if (shouldMerge && _floatingXps.isNotEmpty) {
          _floatingXps.last.value += value;
        } else {
          final adjustedPos = Offset(position.dx, position.dy - 30);
          _floatingXps.add(FloatingXp(
            _xpIdCounter++,
            value,
            adjustedPos,
            (Random().nextDouble() - 0.5) * 40,
          ));
        }
        _progressPulseController.forward(from: 0);
      });
    });
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedIndex = prefs.getInt(_keyExerciseIndex);
    if (savedIndex != null && savedIndex < widget.routine.exercises.length) {
      if (mounted) setState(() => _currentExerciseIndex = savedIndex);
    }

    final setsJson = prefs.getString(_keySetsState);
    if (setsJson != null) {
      try {
        final List<dynamic> data = jsonDecode(setsJson);
        for (int i = 0; i < data.length && i < widget.routine.exercises.length; i++) {
          final List<dynamic> exerciseSets = data[i];
          for (int j = 0; j < exerciseSets.length && j < widget.routine.exercises[i].sets.length; j++) {
            final int statusIndex = exerciseSets[j] as int;
            widget.routine.exercises[i].sets[j].status = SetStatus.values[statusIndex];
          }
        }
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Failed to restore sets state: $e');
      }
    }

    final restStr = prefs.getString(_keyRestEndTime);
    if (restStr != null) {
      final endTime = DateTime.tryParse(restStr);
      if (endTime != null && endTime.isAfter(DateTime.now())) {
        if (mounted) {
          setState(() => _restEndTime = endTime);
          _ticker?.start();
        }
      } else {
        unawaited(prefs.remove(_keyRestEndTime));
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyExerciseIndex, _currentExerciseIndex);
    
    final setsData = widget.routine.exercises.map((e) => e.sets.map((s) => s.status.index).toList()).toList();
    await prefs.setString(_keySetsState, jsonEncode(setsData));
    
    if (_restEndTime != null) {
      await prefs.setString(_keyRestEndTime, _restEndTime!.toIso8601String());
    } else {
      await prefs.remove(_keyRestEndTime);
    }
  }

  void _startSet(WorkoutSet set) {
    if (set.status != SetStatus.idle) return;
    HapticFeedback.lightImpact();
    setState(() {
      set.status = SetStatus.active;
    });
    _saveState();
  }

  void _completeSet(WorkoutSet set, Exercise exercise, Offset tapPosition) {
    if (set.status != SetStatus.active || _workoutComplete) return;
    
    setState(() {
      set.status = SetStatus.resting;
    });

    final int value = set.reps;
    widget.gameService.reportActivity('gym_routine', value);
    _showFloatingXp(value, tapPosition);
    HapticFeedback.heavyImpact();
    
    // Background Flash
    _flashController.forward(from: 0).then((_) => _flashController.reverse());

    _startRest(exercise.restSeconds);
    unawaited(_saveState());
  }

  Future<void> _startRest(int seconds) async {
    final endTime = DateTime.now().add(Duration(seconds: seconds));
    setState(() {
      _restEndTime = endTime;
      if (_ticker != null && !_ticker!.isActive) _ticker!.start();
    });
    unawaited(_saveState());
  }

  Future<void> _stopRest() async {
    final currentExercise = widget.routine.exercises[_currentExerciseIndex];
    WorkoutSet? restingSet;
    try {
      restingSet = currentExercise.sets.firstWhere((s) => s.status == SetStatus.resting);
    } catch (_) {}
    
    setState(() {
      if (restingSet != null) restingSet.status = SetStatus.completed;
      _restEndTime = null;
      if (_ticker != null && _ticker!.isActive) _ticker!.stop();
    });

    if (currentExercise.sets.every((s) => s.status == SetStatus.completed)) {
      _scheduleAutoAdvance();
    }
    unawaited(_saveState());
  }

  void _adjustRest(int deltaSeconds) {
    if (_restEndTime == null) return;
    setState(() {
      _restEndTime = _restEndTime!.add(Duration(seconds: deltaSeconds));
    });
    _saveState();
  }

  void _scheduleAutoAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(seconds: 1), () {
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
    _progressPulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_workoutComplete) return _buildWorkoutComplete();

    final currentExercise = widget.routine.exercises[_currentExerciseIndex];

    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Color.lerp(GameTheme.background, GameTheme.primary.withValues(alpha: 0.2), _flashController.value),
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
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'CURRENT EXERCISE',
                      style: TextStyle(color: GameTheme.primary.withValues(alpha: 0.7), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
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

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: currentExercise.sets.length,
                  itemBuilder: (context, index) {
                    final set = currentExercise.sets[index];
                    return ActiveSetRow(
                      set: set,
                      index: index,
                      isTarget: !set.isCompleted && (index == 0 || currentExercise.sets[index - 1].isCompleted),
                      remainingRestSeconds: _remainingRestSeconds,
                      onStart: () => _startSet(set),
                      onComplete: (pos) => _completeSet(set, currentExercise, pos),
                      onUpdate: (r, w) => setState(() {
                        set.reps = r;
                        set.weight = w;
                      }),
                      onSkipRest: _stopRest,
                      onAdjustRest: _adjustRest,
                    );
                  },
                ),
              ),

              _buildBottomNavigation(),
            ],
          ),

          ..._floatingXps.map((xp) => FloatingXpText(
            key: ValueKey(xp.id),
            xp: xp,
            onComplete: () => setState(() => _floatingXps.removeWhere((e) => e.id == xp.id)),
          )),
        ],
      ),
        );
      },
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
            const Text('MISSION ACCOMPLISHED!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Training data synchronized with Archetype.', style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            _ActionButtonLarge(
              label: 'RETURN TO BASE',
              icon: Icons.home,
              onTap: () => Navigator.pop(context),
              color: GameTheme.primary,
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
        color: GameTheme.border,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(color: GameTheme.accent),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final bool isResting = _remainingRestSeconds > 0;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: (_currentExerciseIndex > 0 && !isResting) ? () {
              setState(() => _currentExerciseIndex--);
              unawaited(_saveState());
            } : null,
            icon: Icon(Icons.arrow_back_ios, color: !isResting ? GameTheme.mutedForeground : GameTheme.mutedForeground.withValues(alpha: 0.2), size: 18),
          ),
          Text(
            'EXERCISE ${_currentExerciseIndex + 1} OF ${widget.routine.exercises.length}',
            style: TextStyle(color: !isResting ? GameTheme.mutedForeground : GameTheme.mutedForeground.withValues(alpha: 0.2), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          IconButton(
            onPressed: (_currentExerciseIndex < widget.routine.exercises.length - 1 && !isResting) 
              ? () {
                setState(() => _currentExerciseIndex++);
                unawaited(_saveState());
              } : null,
            icon: Icon(Icons.arrow_forward_ios, color: !isResting ? GameTheme.mutedForeground : GameTheme.mutedForeground.withValues(alpha: 0.2), size: 18),
          ),
        ],
      ),
    );
  }
}

class ActiveSetRow extends StatelessWidget {
  final WorkoutSet set;
  final int index;
  final bool isTarget;
  final int remainingRestSeconds;
  final VoidCallback onStart;
  final Function(Offset pos) onComplete;
  final Function(int reps, double weight) onUpdate;
  final VoidCallback onSkipRest;
  final Function(int) onAdjustRest;

  const ActiveSetRow({
    super.key,
    required this.set,
    required this.index,
    required this.isTarget,
    required this.remainingRestSeconds,
    required this.onStart,
    required this.onComplete,
    required this.onUpdate,
    required this.onSkipRest,
    required this.onAdjustRest,
  });

  @override
  Widget build(BuildContext context) {
    final status = set.status;
    final bool isActive = status == SetStatus.active;
    final bool isCompleted = status == SetStatus.completed;
    final bool isResting = status == SetStatus.resting;
    
    final bool isInteractable = (isTarget && status == SetStatus.idle) || isActive || isResting;
    final double opacity = isInteractable ? 1.0 : (isCompleted ? 0.6 : 0.4);

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isTarget ? 1.03 : 1.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? GameTheme.primary.withValues(alpha: 0.1) : (isCompleted ? GameTheme.cardBg.withValues(alpha: 0.5) : GameTheme.cardBg),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTarget ? GameTheme.primary : (isCompleted ? GameTheme.primary.withValues(alpha: 0.3) : GameTheme.border),
              width: isTarget ? 2 : 1,
            ),
            boxShadow: isTarget ? [
              BoxShadow(color: GameTheme.primary.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2)
            ] : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isCompleted ? GameTheme.primary : (isTarget ? GameTheme.primary : GameTheme.background),
                    child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCompleted || isTarget ? Colors.white : GameTheme.mutedForeground)),
                  ),
                  const SizedBox(width: 12),
                  if (isCompleted)
                    const Text('COMPLETED', style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold, fontSize: 12))
                  else if (isResting)
                    const Text('RECOVERING', style: TextStyle(color: GameTheme.accent, fontWeight: FontWeight.bold, fontSize: 12))
                  else if (isActive)
                    const Text('SET IN PROGRESS', style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold, fontSize: 12))
                  else if (isTarget)
                    const Text('YOUR TURN', style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold, fontSize: 12))
                  else
                    Text('UPCOMING', style: TextStyle(color: GameTheme.mutedForeground.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 12)),
                  
                  const Spacer(),
                  
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: GameTheme.primary, size: 24)
                ],
              ),
              if (!isCompleted && !isResting) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StepperControl(
                        label: 'REPS',
                        value: set.reps,
                        step: 1,
                        enabled: status == SetStatus.idle && isTarget,
                        onChanged: (v) => onUpdate(v.toInt().clamp(1, 100), set.weight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StepperControl(
                        label: 'WEIGHT',
                        value: set.weight,
                        step: 2.5,
                        suffix: 'KG',
                        enabled: status == SetStatus.idle && isTarget,
                        onChanged: (v) => onUpdate(set.reps, v.toDouble().clamp(0, 500)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (status == SetStatus.idle && isTarget)
                  _ActionButtonLarge(
                    label: 'START SET',
                    icon: Icons.play_arrow,
                    onTap: onStart,
                    color: GameTheme.primary,
                  )
                else if (status == SetStatus.active)
                  _ActionButtonLarge(
                    label: 'COMPLETE SET',
                    icon: Icons.flash_on,
                    onTapDown: (details) => onComplete(details.globalPosition),
                    color: GameTheme.accent,
                    pulse: true,
                  )
              ],
              if (isResting) ...[
                const SizedBox(height: 16),
                RestTimerWidget(
                  seconds: remainingRestSeconds,
                  onSkip: onSkipRest,
                  onAdjust: onAdjustRest,
                ),
              ],
              if (isCompleted) ...[
                 const SizedBox(height: 8),
                 Row(
                   children: [
                     const SizedBox(width: 40),
                     Text('${set.reps} REPS', style: const TextStyle(fontWeight: FontWeight.bold)),
                     const Text(' @ ', style: TextStyle(color: GameTheme.mutedForeground)),
                     Text('${set.weight} KG', style: const TextStyle(fontWeight: FontWeight.bold)),
                   ],
                 )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class StepperControl extends StatelessWidget {
  final String label;
  final num value;
  final num step;
  final Function(num) onChanged;
  final String? suffix;
  final bool enabled;

  const StepperControl({
    super.key,
    required this.label,
    required this.value,
    required this.step,
    required this.onChanged,
    this.suffix,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: GameTheme.mutedForeground, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: GameTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GameTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepButton(icon: Icons.remove, enabled: enabled, onTap: () => onChanged(value - step)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      value is int ? value.toString() : value.toStringAsFixed(1),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: enabled ? GameTheme.foreground : GameTheme.mutedForeground),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 2),
                      Text(suffix!, style: TextStyle(fontSize: 10, color: (enabled ? GameTheme.mutedForeground : GameTheme.mutedForeground.withValues(alpha: 0.3)))),
                    ],
                  ],
                ),
              ),
              _StepButton(icon: Icons.add, enabled: enabled, onTap: () => onChanged(value + step)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.lightImpact();
        onTap();
      } : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? GameTheme.cardBg : GameTheme.cardBg.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: enabled ? GameTheme.primary : GameTheme.mutedForeground.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _ActionButtonLarge extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Function(TapDownDetails)? onTapDown;
  final Color color;
  final bool pulse;

  const _ActionButtonLarge({
    required this.label, 
    required this.icon, 
    this.onTap, 
    this.onTapDown, 
    required this.color,
    this.pulse = false,
  });

  @override
  State<_ActionButtonLarge> createState() => _ActionButtonLargeState();
}

class _ActionButtonLargeState extends State<_ActionButtonLarge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    if (widget.pulse) _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTapDown,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: widget.pulse ? 0.3 + (_pulseController.value * 0.2) : 0.3),
                  blurRadius: widget.pulse ? 10 + (_pulseController.value * 10) : 10,
                  spreadRadius: widget.pulse ? _pulseController.value * 2 : 0,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}

class RestTimerWidget extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;
  final Function(int) onAdjust;

  const RestTimerWidget({super.key, required this.seconds, required this.onSkip, required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: GameTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: GameTheme.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RESTING', style: TextStyle(color: GameTheme.accent, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1)),
                    Text(
                      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: GameTheme.foreground, fontSize: 24, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSkip,
                child: const Text('SKIP', style: TextStyle(color: GameTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimerAdjustButton(label: '-15s', onTap: () => onAdjust(-15)),
              const SizedBox(width: 16),
              _TimerAdjustButton(label: '+15s', onTap: () => onAdjust(15)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerAdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimerAdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GameTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameTheme.border),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: GameTheme.mutedForeground)),
      ),
    );
  }
}

class FloatingXpText extends StatefulWidget {
  final FloatingXp xp;
  final VoidCallback onComplete;

  const FloatingXpText({super.key, required this.xp, required this.onComplete});

  @override
  State<FloatingXpText> createState() => FloatingXpTextState();
}

class FloatingXpTextState extends State<FloatingXpText> with SingleTickerProviderStateMixin {
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
    final screenWidth = MediaQuery.of(context).size.width;
    double safeX = widget.xp.position.dx + widget.xp.drift;
    safeX = safeX.clamp(16.0, screenWidth - 80.0);

    return Positioned(
      left: safeX,
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
                      BoxShadow(color: GameTheme.accent.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1),
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
