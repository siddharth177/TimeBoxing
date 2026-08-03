import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeboxing/core/providers/firebase_providers.dart';
import 'package:timeboxing/features/timeline/models/time_block.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

final timeBlocksProvider = StreamProvider<List<TimeBlock>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('timeBlocks')
      .orderBy('startTime')
      .snapshots()
      .map((snap) => snap.docs.map((d) => TimeBlock.fromDoc(d)).toList());
});

final timeBlocksRepoProvider = Provider<TimeBlocksRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return TimeBlocksRepository(user.uid);
});

class TimeBlocksRepository {
  TimeBlocksRepository(this._uid);

  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('timeBlocks');

  String get newId => _uuid.v4();

  Future<void> add(TimeBlock block) => _col.doc(block.id).set(block.toMap());

  Future<void> update(TimeBlock block) =>
      _col.doc(block.id).update(block.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> toggleComplete(String id, bool current) =>
      _col.doc(id).update({'isCompleted': !current});

  Future<void> deleteByTaskId(String taskId) async {
    final snap = await _col.where('taskId', isEqualTo: taskId).get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

final currentOrNextBlockProvider = Provider<TimeBlock?>((ref) {
  final blocks = ref.watch(timeBlocksProvider).value ?? [];
  final now = DateTime.now();
  final sorted = [...blocks]
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  final current = sorted.where((b) => b.isNow).firstOrNull;
  if (current != null) return current;
  return sorted.where((b) => b.startTime.isAfter(now)).firstOrNull;
});
