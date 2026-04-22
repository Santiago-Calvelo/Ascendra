import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/task.dart';
import 'game_theme.dart';

// ────────────────────────────────────────────────────────────────────────────
// ENUM
// ────────────────────────────────────────────────────────────────────────────

enum Archetype { body, mind, soul }

// ────────────────────────────────────────────────────────────────────────────
// STYLE CONFIG
// ────────────────────────────────────────────────────────────────────────────

class ArchetypeStyle {
  final String svgPath;
  final Color primary;
  final Color glow;
  final String label;

  const ArchetypeStyle({
    required this.svgPath,
    required this.primary,
    required this.glow,
    required this.label,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// MAPPING FUNCTIONS
// ────────────────────────────────────────────────────────────────────────────

Archetype getArchetype(Task task) {
  // ignore: dead_null_aware_expression
  final id = (task.activityId ?? '').toLowerCase();
  if (id.contains('gym') || id.contains('steps') || id.contains('cardio')) {
    return Archetype.body;
  }
  if (id.contains('focus') || id.contains('study')) {
    return Archetype.mind;
  }
  return Archetype.soul;
}

ArchetypeStyle getStyle(Archetype type) {
  switch (type) {
    case Archetype.body:
      return const ArchetypeStyle(
        svgPath: 'assets/icons/body.svg',
        primary: GameTheme.statStr,
        glow: Colors.redAccent,
        label: 'BODY',
      );
    case Archetype.mind:
      return const ArchetypeStyle(
        svgPath: 'assets/icons/mind.svg',
        primary: GameTheme.statDis,
        glow: Colors.blueAccent,
        label: 'MIND',
      );
    case Archetype.soul:
      return const ArchetypeStyle(
        svgPath: 'assets/icons/soul.svg',
        primary: GameTheme.accent,
        glow: Colors.amberAccent,
        label: 'SOUL',
      );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STAT NAME HELPER  (for reward rows)
// ────────────────────────────────────────────────────────────────────────────

String getStatName(Archetype type) {
  switch (type) {
    case Archetype.body:
      return 'STR';
    case Archetype.mind:
      return 'DIS';
    case Archetype.soul:
      return 'ALL';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// RPG ICON WIDGET (SIMPLE & DIRECT RENDERING)
// ────────────────────────────────────────────────────────────────────────────

Widget buildRpgIcon(ArchetypeStyle style, bool isCompleted, {double size = 54}) {
  final svgPath = isCompleted ? 'assets/icons/check.svg' : style.svgPath;

  // Use high-contrast colors to ensure visibility against dark gradients
  final iconColor = isCompleted
      ? Colors.white
      : style.primary.withValues(alpha: 0.95);

  final glowColor = isCompleted
      ? Colors.greenAccent
      : style.glow;

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment.topLeft,
        radius: 1.1,
        colors: [
          style.primary.withValues(alpha: 0.3),
          Colors.black.withValues(alpha: 0.8),
        ],
      ),
      border: Border.all(
        color: iconColor.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: isCompleted ? 0.6 : 0.3),
          blurRadius: isCompleted ? 20 : 12,
          spreadRadius: isCompleted ? 2 : 0,
        ),
      ],
    ),
    child: Center(
      // ignore: deprecated_member_use
      child: SvgPicture.asset(
        svgPath,
        // Using direct color is simpler and avoids the fragile ColorFilter 
        // compositing issues often found in complex nested decorations.
        color: iconColor,
        width: size * 0.65, // Significant size increase for impact
        height: size * 0.65,
        fit: BoxFit.contain,
      ),
    ),
  );
}
