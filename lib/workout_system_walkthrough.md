# RPG Workout System: Design & Structure

The Workout System is designed to feel like an interactive training mission rather than a spreadsheet. It prioritizes speed, feedback, and automation.

## 1. The Workout Builder (Setup Mode)
Located in the **Routines Tab**, this screen is for strategic planning.
- **Fast Editing**: Use expandable cards to focus on one exercise at a time.
- **Set Management**: Add or remove sets with a single tap. Inline fields allow quick adjustments to reps and weights.
- **Rest Strategy**: Define rest periods per exercise to automate the session later.

## 2. Workout Execution (Action Mode)
Triggered when you start a **Gym Task**.
- **Action Rows**: Each set is a large, actionable button. Tap to "Execute" the set.
- **Visual Progression**: Completed sets light up with the primary magic color (Violet/Primary), giving immediate satisfaction.
- **Session Focus**: Only the current exercise is shown in detail, keeping you focused on the task at hand.

## 3. The Automatic Rest Engine
This is the heart of the "Game Feel".
- **Zero-Tap Timing**: As soon as you finish a set, the **Rest Timer** appears automatically.
- **Overlay UI**: The `RestTimerWidget` is an amber-accented overlay that provides a clear countdown while allowing you to see the next set's requirements.
- **Background Readiness**: The system is structured to support background notifications, ensuring you never miss your next set even if you lock your phone.

## 4. Interaction Flow
1. **Prepare**: Open the Gym Quest.
2. **Execute**: Perform the reps and tap the Set Row.
3. **Recover**: The Rest Overlay appears; catch your breath.
4. **Repeat**: Timer ends (vibration/nudge) → Next set is ready.
5. **Level Up**: Finish all exercises to complete the Quest and earn XP.

## 5. Widget Structure
- `RoutineBuilderScreen`: The top-level routine editor.
- `ExerciseBuilderCard`: Expandable exercise detail in the builder.
- `WorkoutExecutionScreen`: The high-intensity session interface.
- `ActiveSetRow`: The primary interaction element during workouts.
- `RestTimerWidget`: The automated recovery countdown.

---
**Design Note**: We've removed "Submit" buttons and manual "Start Timer" steps to keep the momentum high, making the app feel like a responsive training partner.
