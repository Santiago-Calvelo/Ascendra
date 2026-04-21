import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'game_service.dart';

/// Architecture: Health Integration Layer
/// 
/// Simplified version focusing on maintainability and core correctness.
class HealthService {
  final GameService _gs;
  final Set<String> _processedIds = {}; // Record Deduplication
  DateTime? lastSyncTime;
  int lastTotalSteps = 0;

  HealthService(this._gs);

  Future<void> syncData() async {
    try {
      final now = DateTime.now();
      final syncStart = lastSyncTime ?? now.subtract(const Duration(hours: 24));
      
      final records = await _fetchRawRecords(syncStart, now);
      
      // 1. Calculate Delta via Deduplication
      int stepDelta = 0;
      for (final r in records) {
        if (_processedIds.contains(r.id)) continue;
        
        // Validation: Steps Per Minute (SPM) Cap
        final durationMin = r.endTime.difference(r.startTime).inMinutes.clamp(1, 1440);
        if (r.value / durationMin <= 200) {
          stepDelta += r.value;
          _processedIds.add(r.id);
        }
      }

      // 2. Fallback: Platform Total Comparison (if records missing)
      final platformTotal = await _getPlatformTotal();
      if (lastTotalSteps > 0 && platformTotal > lastTotalSteps) {
        final platformDelta = platformTotal - lastTotalSteps;
        if (platformDelta > stepDelta) {
          stepDelta = platformDelta.clamp(0, 15000); // Sanity cap for fallback
        }
      }
      lastTotalSteps = platformTotal;

      if (stepDelta > 0) {
        await _dispatchChunks(stepDelta);
        lastSyncTime = now;
        _gs.save();
      }
    } catch (e) {
      debugPrint('Health sync failed: $e');
    }
  }

  Future<void> _dispatchChunks(int total) async {
    // Fix #8: Adaptive chunk size (approx 10% of total, but between 200 and 1000)
    final chunkSize = (total / 10).round().clamp(200, 1000);
    
    int sent = 0;
    while (sent < total) {
      final chunk = (total - sent) > chunkSize ? chunkSize : (total - sent);
      _gs.reportActivity('cardio_steps', chunk);
      sent += chunk;
      
      if (sent < total) {
        // Dynamic delay based on chunk size for natural feel
        await Future.delayed(Duration(milliseconds: 300 + (chunk ~/ 10)));
      }
    }
  }

  Future<int> _getPlatformTotal() async => 0; // Mock

  Future<List<HealthRecord>> _fetchRawRecords(DateTime start, DateTime end) async {
    return []; // Mock
  }
}
