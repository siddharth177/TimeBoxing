import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../models/daily_log.dart';

final dailyLogsProvider = StreamProvider<List<DailyLog>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final cutoff = DateTime.now().subtract(const Duration(days: 90));
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('dailyLogs')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DailyLog.fromDoc(d)).toList());
});

final currentStreakProvider = Provider<int>((ref) {
  final logs = ref.watch(dailyLogsProvider).value ?? [];
  if (logs.isEmpty) return 0;

  final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
  int streak = 0;
  DateTime cursor = DateTime.now();

  for (final log in sorted) {
    final logDay = DateTime(log.date.year, log.date.month, log.date.day);
    final cursorDay = DateTime(cursor.year, cursor.month, cursor.day);
    final diff = cursorDay.difference(logDay).inDays;

    if (diff > 1) break; // gap — streak ends

    if (log.totalItems == 0) {
      // No tasks planned that day — neutral, slide cursor but don't count.
      cursor = logDay;
      continue;
    }

    if (log.completionRate >= 0.5) {
      streak++;
      cursor = logDay;
    } else {
      break;
    }
  }
  return streak;
});

final reviewRepoProvider = Provider<ReviewRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ReviewRepository(user.uid);
});

class ReviewRepository {
  ReviewRepository(this._uid);

  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('dailyLogs');

  Future<DailyLog?> getLog(DateTime date) async {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final snap = await _col.doc(key).get();
    if (!snap.exists || snap.data() == null) return null;
    return DailyLog.fromDoc(snap);
  }

  Future<void> saveLog(DailyLog log) =>
      _col.doc(log.dateKey).set(log.toMap(), SetOptions(merge: true));
}
