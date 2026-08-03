import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeBlockType { task, chore, recurring, free }

class TimeBlock {
  const TimeBlock({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.type = TimeBlockType.task,
    this.isCompleted = false,
    this.color,
    this.notes,
    this.taskId,
    this.calendarEventId,
    this.calendarId,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final TimeBlockType type;
  final bool isCompleted;
  final Color? color;
  final String? notes;
  final String? taskId;
  final String? calendarEventId;
  final String? calendarId;

  Duration get duration => endTime.difference(startTime);

  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'type': type.name,
    'isCompleted': isCompleted,
    'colorValue': color?.toARGB32(),
    'notes': notes,
    'taskId': taskId,
    'calendarEventId': calendarEventId,
    'calendarId': calendarId,
  };

  factory TimeBlock.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return TimeBlock(
      id: doc.id,
      title: d!['title'] as String,
      startTime: (d['startTime'] as Timestamp).toDate(),
      endTime: (d['endTime'] as Timestamp).toDate(),
      type: TimeBlockType.values.byName(d['type'] as String ?? 'task'),
      isCompleted: d['isCompleted'] as bool ?? false,
      color: d['colorValue'] != null ? Color(d['colorValue'] as int) : null,
      notes: d['notes'] as String?,
      taskId: d['taskId'] as String?,
      calendarEventId: d['calendarEventId'] as String?,
      calendarId: d['calendarId'] as String?,
    );
  }

  TimeBlock copyWith({
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    TimeBlockType? type,
    bool? isCompleted,
    Color? color,
    String? notes,
    String? taskId,
    String? calendarEventId,
    String? calendarId,
  }) => TimeBlock(
    id: id,
    title: title ?? this.title,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    type: type ?? this.type,
    isCompleted: isCompleted ?? this.isCompleted,
    color: color ?? this.color,
    notes: notes ?? this.notes,
    taskId: taskId ?? this.taskId,
    calendarEventId: calendarEventId ?? this.calendarEventId,
    calendarId: calendarId ?? this.calendarId,
  );
}
