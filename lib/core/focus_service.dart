import '../models/user.dart';

class FocusService {
  bool isFocusMode = false;
  int focusDuration = 25;
  DateTime? focusStartTime;

  void start(int minutes) {
    isFocusMode = true;
    focusDuration = minutes;
    focusStartTime = DateTime.now();
  }

  bool complete({
    required User user,
    double intensityFactor = 1.0,
    required Function(int) onXpReward,
    required Function() onCancel,
  }) {
    if (!isFocusMode || focusStartTime == null) return false;

    final elapsed = DateTime.now().difference(focusStartTime!).inSeconds;
    if (elapsed < (focusDuration * 60) - 2) {
      onCancel();
      return false;
    }

    final reward = (focusDuration * 1.2 * intensityFactor).round();
    user.addXP(reward);
    user.incrementStat('disciplina', 1);

    onXpReward(reward);

    isFocusMode = false;
    focusStartTime = null;
    return true;
  }

  void cancel() {
    isFocusMode = false;
    focusStartTime = null;
  }
}
