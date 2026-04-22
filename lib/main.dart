import 'dart:async';
import 'package:flutter/material.dart';

import 'core/game_service.dart';
import 'models/workout.dart';
import 'models/achievement.dart';
import 'ui_mobile/screens/quest_board_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitRPGApp());
}

// â”€â”€â”€ App Root â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class HabitRPGApp extends StatelessWidget {
  const HabitRPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      home: const HabitScreen(),
    );
  }
}

// â”€â”€â”€ Main Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final GameService _gs = GameService();
  int _currentIndex = 0;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _gs.load().then((_) {
      _gs.onAchievementUnlocked = (ach) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ðŸ† UNLOCKED: ${ach.title}'),
          backgroundColor: const Color(0xFF7C3AED),
        ));
      };
      _gs.onMilestone = (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('âœ¨ $msg'),
          backgroundColor: Colors.blueAccent,
        ));
      };
      setState(() {});
      if (_gs.isFocusMode) _startTimer();
    });
  }

  void _startTimer() {
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_gs.isFocusMode) { t.cancel(); return; }
      setState(() {
        final end = _gs.focusStartTime!.add(Duration(minutes: _gs.focusDuration));
        if (DateTime.now().isAfter(end)) {
          t.cancel();
          _gs.completeFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            QuestBoardScreen(gs: _gs),
            _GymView(gs: _gs),
            _FocusView(gs: _gs, onToggle: () {
              if (_gs.isFocusMode) {
                _gs.cancelFocus();
                _focusTimer?.cancel();
              } else {
                _gs.startFocus(25);
                _startTimer();
              }
              setState(() {});
            }),
            _StatsView(gs: _gs),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1625),
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: Colors.white24,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Gym'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Focus'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

class _GymView extends StatelessWidget {
  final GameService gs;
  const _GymView({required this.gs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: gs.workout.exercises.length,
      itemBuilder: (_, i) {
        final ex = gs.workout.exercises[i];
        return Card(
          color: const Color(0xFF1E1B2E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(ex.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(ex.type.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _WorkoutSessionScreen(gs: gs, exercise: ex))),
          ),
        );
      },
    );
  }
}

class _FocusView extends StatelessWidget {
  final GameService gs;
  final VoidCallback onToggle;
  const _FocusView({required this.gs, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final end = (gs.focusStartTime ?? now).add(Duration(minutes: gs.focusDuration));
    final diff = end.isAfter(now) ? end.difference(now) : Duration.zero;
    final timeStr = '${diff.inMinutes.toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(gs.isFocusMode ? timeStr : '25:00', style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w100)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
            child: Text(gs.isFocusMode ? 'STOP FOCUS' : 'START FOCUS', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  final GameService gs;
  const _StatsView({required this.gs});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('STATISTICS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 16),
        ...gs.user.stats.entries.map((e) => _StatRow(label: e.key.toUpperCase(), value: e.value)),
        const SizedBox(height: 40),
        const Text('ACHIEVEMENTS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 16),
        ...gs.achievements.map((a) => _AchievementMiniCard(a: a)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text('$value', style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AchievementMiniCard extends StatelessWidget {
  final Achievement a;
  const _AchievementMiniCard({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(a.unlocked ? Icons.emoji_events : Icons.lock, color: a.unlocked ? Colors.amber : Colors.white24, size: 16),
          const SizedBox(width: 12),
          Text(a.title, style: TextStyle(color: a.unlocked ? Colors.white : Colors.white38, fontSize: 13)),
          const Spacer(),
          Text('${a.progress}/${a.target}', style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}

class _WorkoutSessionScreen extends StatefulWidget {
  final GameService gs;
  final Exercise exercise;
  const _WorkoutSessionScreen({required this.gs, required this.exercise});

  @override
  State<_WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<_WorkoutSessionScreen> {
  final Map<String, TextEditingController> _ctrls = {
    'weight': TextEditingController(),
    'reps': TextEditingController(),
    'duration': TextEditingController(),
    'speed': TextEditingController(),
    'incline': TextEditingController(),
  };

  final List<WorkoutEntry> _sets = [];

  double _pD(String k) => double.tryParse(_ctrls[k]!.text) ?? 0;
  int _pI(String k) => int.tryParse(_ctrls[k]!.text) ?? 0;
  bool get _isStr => widget.exercise.type == 'strength';

  @override
  void initState() {
    super.initState();
    _sets
        .addAll((widget.gs.workout.history[widget.exercise.id] ?? []).reversed);
  }

  void _addSet() {
    final entry = WorkoutEntry(
      weight: _pD('weight'),
      reps: _pI('reps'),
      duration: _pI('duration'),
      speed: _pD('speed'),
      incline: _pD('incline'),
    );

    if (_isStr && (entry.reps ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter valid reps'),
          backgroundColor: Colors.redAccent));
      return;
    }
    if (!_isStr && (entry.duration ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter valid duration'),
          backgroundColor: Colors.redAccent));
      return;
    }

    final isPR = widget.gs.workout
        .checkPR(widget.exercise.id, entry, widget.exercise.type);
    final finalEntry = WorkoutEntry(
      weight: entry.weight,
      reps: entry.reps,
      duration: entry.duration,
      speed: entry.speed,
      incline: entry.incline,
      isPR: isPR,
    );

    final res = widget.gs.addWorkoutEntry(widget.exercise.id, finalEntry);
    final statName = _isStr ? 'fuerza' : 'resistencia';

    setState(() {
      _sets.insert(0, finalEntry);
      for (var c in _ctrls.values) {
        c.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${isPR ? 'ðŸ† NEW RECORD! ' : ''}+${res['xp']} XP | +${res['statGain']} $statName'),
      backgroundColor: isPR ? Colors.orangeAccent : Colors.green,
    ));
  }

  WorkoutEntry? get _bestSet {
    if (_sets.isEmpty) return null;
    return _sets.reduce((a, b) {
      // We already have a score method in service, but for UI we use the local list
      // To keep it simple and identical behavior:
      if (_isStr) {
        return ((a.weight ?? 0) * (a.reps ?? 0)) >=
                ((b.weight ?? 0) * (b.reps ?? 0))
            ? a
            : b;
      }
      return ((a.duration ?? 0) * (a.speed ?? 0)) >=
              ((b.duration ?? 0) * (b.speed ?? 0))
          ? a
          : b;
    });
  }

  String _fmt(WorkoutEntry? s) {
    if (s == null) return '-';
    return _isStr ? '${s.reps}x${s.weight}kg' : '${s.duration}m@${s.speed}';
  }

  double get _totalVolume =>
      _sets.fold(0.0, (sum, s) => sum + (s.weight ?? 0) * (s.reps ?? 0));

  @override
  Widget build(BuildContext context) {
    final isStr = widget.exercise.type == 'strength';
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: Text(widget.exercise.name,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isStr) ...[
              TextField(
                  controller: _ctrls['weight'],
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Weight (kg)'),
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(
                  controller: _ctrls['reps'],
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Reps'),
                  style: const TextStyle(color: Colors.white)),
            ] else ...[
              TextField(
                  controller: _ctrls['duration'],
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Duration (min)'),
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(
                  controller: _ctrls['speed'],
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Speed (km/h)'),
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(
                  controller: _ctrls['incline'],
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Incline'),
                  style: const TextStyle(color: Colors.white)),
            ],
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                    child: _statBox(
                        'LAST', _fmt(_sets.isNotEmpty ? _sets.first : null))),
                const SizedBox(width: 12),
                Expanded(child: _statBox('BEST', _fmt(_bestSet))),
                if (isStr) ...[
                  const SizedBox(width: 12),
                  Expanded(
                      child: _statBox('VOLUME', '${_totalVolume.round()}kg')),
                ],
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addSet,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('ADD SET',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('PREVIOUS SETS',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1))),
            const SizedBox(height: 12),
            Expanded(
              child: _sets.isEmpty
                  ? const Center(
                      child: Text('No sets yet',
                          style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      itemCount: _sets.length,
                      itemBuilder: (_, i) {
                        final s = _sets[i];
                        final isLatest = i == 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: s.isPR
                                ? Colors.amber.withValues(alpha: 0.1)
                                : (isLatest
                                    ? Colors.green.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: s.isPR
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                isStr
                                    ? '${s.reps ?? 0} reps @ ${s.weight ?? 0} kg'
                                    : '${s.duration ?? 0} min @ ${s.speed ?? 0} km/h (incl. ${s.incline ?? 0})',
                                style: TextStyle(
                                  color: s.isPR
                                      ? Colors.amber
                                      : (isLatest
                                          ? Colors.greenAccent
                                          : Colors.white70),
                                  fontFamily: 'monospace',
                                  fontWeight: isLatest || s.isPR
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (s.isPR)
                                const Icon(Icons.workspace_premium,
                                    color: Colors.amber, size: 16),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  Widget _statBox(String label, String val) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(val,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  @override
  void dispose() {
    for (var c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}


