import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLog {
  const DailyLog({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalChores,
    required this.completedChores,
    this.streak = 0,
    this.reflection,
    this.mood,
    this.skippedTaskIds = const [],
  });

  final DateTime date;
  final int totalTasks;
  final int completedTasks;
  final int totalChores;
  final int completedChores;
  final int streak;
  final String? reflection;

  /// Energy/mood rating 1–5. Null = not rated.
  final int? mood;

  /// Task IDs explicitly marked as skipped during review.
  final List<String> skippedTaskIds;

  String get dateKey {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int get totalItems => totalTasks + totalChores;

  int get completedItems => completedTasks + completedChores;

  double get completionRate {
    if (totalItems == 0) return 0;
    return completedItems / totalItems;
  }

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'totalTasks': totalTasks,
    'completedTasks': completedTasks,
    'totalChores': totalChores,
    'completedChores': completedChores,
    'streak': streak,
    'reflection': reflection,
    'mood': mood,
    'skippedTaskIds': skippedTaskIds,
  };

  factory DailyLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DailyLog(
      date: (d['date'] as Timestamp).toDate(),
      totalTasks: d['totalTasks'] as int? ?? 0,
      completedTasks: d['completedTasks'] as int? ?? 0,
      totalChores: d['totalChores'] as int? ?? 0,
      completedChores: d['completedChores'] as int? ?? 0,
      streak: d['streak'] as int? ?? 0,
      reflection: d['reflection'] as String?,
      mood: d['mood'] as int?,
      skippedTaskIds:
          (d['skippedTaskIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  DailyLog copyWith({
    int? streak,
    String? reflection,
    int? mood,
    List<String>? skippedTaskIds,
  }) => DailyLog(
    date: date,
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    totalChores: totalChores,
    completedChores: completedChores,
    streak: streak ?? this.streak,
    reflection: reflection ?? this.reflection,
    mood: mood ?? this.mood,
    skippedTaskIds: skippedTaskIds ?? this.skippedTaskIds,
  );
}
