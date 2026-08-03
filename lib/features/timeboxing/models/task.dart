import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskLevel { priority, chore }

enum RecurrenceType { daily, specificDays, weekly, fortnightly, monthly }

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.level,
    required this.order,
    required this.date,
    this.isCompleted = false,
    this.notes,
    this.isRecurring = false,
    this.recurrenceType,
    this.recurrenceDays,
    this.reminderOffsetMinutes,
    this.goalId,
  });

  final String id;
  final String title;
  final TaskLevel level;
  final int order;
  final DateTime date;
  final bool isCompleted;
  final String? notes;
  final bool isRecurring;
  final RecurrenceType? recurrenceType;
  final List<int>? recurrenceDays; // 1=Mon .. 7=Sun
  final int? reminderOffsetMinutes; // null=none, 0=at start, 5/10/15=before
  final String? goalId; // links a priority task to a short-term goal

  Map<String, dynamic> toMap() => {
    'title': title,
    'level': level.name,
    'order': order,
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'isCompleted': isCompleted,
    'notes': notes,
    'isRecurring': isRecurring,
    'recurrenceType': recurrenceType?.name,
    'recurrenceDays': recurrenceDays,
    'reminderOffsetMinutes': reminderOffsetMinutes,
    'goalId': goalId,
  };

  factory Task.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Task(
      id: doc.id,
      title: d['title'] as String,
      level: TaskLevel.values.byName(d['level'] as String? ?? 'priority'),
      order: d['order'] as int? ?? 0,
      date: (d['date'] as Timestamp).toDate(),
      isCompleted: d['isCompleted'] as bool? ?? false,
      notes: d['notes'] as String?,
      isRecurring: d['isRecurring'] as bool? ?? false,
      recurrenceType: d['recurrenceType'] != null
          ? RecurrenceType.values.byName(d['recurrenceType'] as String)
          : null,
      recurrenceDays: (d['recurrenceDays'] as List?)?.cast<int>(),
      reminderOffsetMinutes: d['reminderOffsetMinutes'] as int?,
      goalId: d['goalId'] as String?,
    );
  }

  Task copyWith({
    String? title,
    TaskLevel? level,
    int? order,
    DateTime? date,
    bool? isCompleted,
    String? notes,
    bool? isRecurring,
    RecurrenceType? recurrenceType,
    List<int>? recurrenceDays,
    int? reminderOffsetMinutes,
    String? goalId,
  }) => Task(
    id: id,
    title: title ?? this.title,
    level: level ?? this.level,
    order: order ?? this.order,
    date: date ?? this.date,
    isCompleted: isCompleted ?? this.isCompleted,
    notes: notes ?? this.notes,
    isRecurring: isRecurring ?? this.isRecurring,
    recurrenceType: recurrenceType ?? this.recurrenceType,
    recurrenceDays: recurrenceDays ?? this.recurrenceDays,
    reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
    goalId: goalId ?? this.goalId,
  );
}
