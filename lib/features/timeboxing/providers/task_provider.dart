import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/firebase_providers.dart';
import '../models/task.dart';

final _uuid = const Uuid();

final timeboxingDayProvider = NotifierProvider<_DayNotifier, DateTime>(
  _DayNotifier.new,
);

class _DayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void set(DateTime day) => state = day;
}

final tasksProvider = StreamProvider.family<List<Task>, DateTime>((ref, day) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('tasks')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end))
      .snapshots()
      .map((snap) {
        final tasks = snap.docs.map((d) => Task.fromDoc(d)).toList();
        tasks.sort((a, b) => a.order.compareTo(b.order));
        return tasks;
      });
});

final tasksRepoProvider = Provider<TasksRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return TasksRepository(user.uid);
});

class TasksRepository {
  TasksRepository(this._uid);

  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('tasks');

  CollectionReference<Map<String, dynamic>> get _blocksCol => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('timeBlocks');

  String get newId => _uuid.v4();

  Future<void> add(Task task) => _col.doc(task.id).set(task.toMap());

  /// Writes one task doc per date in [dates] as a single Firestore batch.
  /// Used for recurring tasks so each day gets its own independent instance.
  Future<void> addRecurring(Task template, List<DateTime> dates) {
    final batch = FirebaseFirestore.instance.batch();
    for (final date in dates) {
      final id = _uuid.v4();
      final task = Task(
        id: id,
        title: template.title,
        level: template.level,
        order: template.order,
        date: date,
        notes: template.notes,
        isRecurring: template.isRecurring,
        recurrenceType: template.recurrenceType,
        recurrenceDays: template.recurrenceDays,
        reminderOffsetMinutes: template.reminderOffsetMinutes,
        goalId: template.goalId,
      );
      batch.set(_col.doc(id), task.toMap());
    }
    return batch.commit();
  }

  Future<void> update(Task task) => _col.doc(task.id).update(task.toMap());

  Future<void> toggleComplete(String id, bool current) =>
      _col.doc(id).update({'isCompleted': !current});

  Future<void> delete(String id) async {
    final snap = await _blocksCol.where('taskId', isEqualTo: id).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_col.doc(id));
    await batch.commit();
  }
}
