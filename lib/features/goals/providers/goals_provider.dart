import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';

const _uuid = Uuid();

enum GoalTier { short, medium, long }

extension GoalTierX on GoalTier {
  String get label => switch (this) {
    GoalTier.short => 'Short-term',
    GoalTier.medium => 'Medium-term',
    GoalTier.long => 'Long-term',
  };

  String get hint => switch (this) {
    GoalTier.short => 'What do you want to achieve in the next 1–3 months?',
    GoalTier.medium => 'What do you want in the next 3–6 months?',
    GoalTier.long => 'What defines your life vision?',
  };

  String get collection => switch (this) {
    GoalTier.short => 'goals',
    GoalTier.medium => 'medium_goals',
    GoalTier.long => 'long_goals',
  };

  GoalTier? get parent => switch (this) {
    GoalTier.long => null,
    GoalTier.medium => GoalTier.long,
    GoalTier.short => GoalTier.medium,
  };
}

enum GoalItemType { goal, milestone, checkpoint }

extension GoalItemTypeX on GoalItemType {
  String get label => switch (this) {
    GoalItemType.goal => 'Goal',
    GoalItemType.milestone => 'Milestone',
    GoalItemType.checkpoint => 'Checkpoint',
  };

  Color get color => switch (this) {
    GoalItemType.goal => AppColors.green60,
    GoalItemType.milestone => AppColors.orange40,
    GoalItemType.checkpoint => AppColors.blue60,
  };

  String get verb => switch (this) {
    GoalItemType.goal => 'completed',
    GoalItemType.milestone => 'achieved',
    GoalItemType.checkpoint => 'passed',
  };
}

enum GoalCategory { work, personal, health, learning }

extension GoalCategoryX on GoalCategory {
  String get label => switch (this) {
    GoalCategory.work => 'Work',
    GoalCategory.personal => 'Personal',
    GoalCategory.health => 'Health',
    GoalCategory.learning => 'Learning',
  };

  Color get color => switch (this) {
    GoalCategory.work => AppColors.brown60,
    GoalCategory.personal => AppColors.purple60,
    GoalCategory.health => AppColors.green60,
    GoalCategory.learning => AppColors.orange40,
  };
}

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.category = GoalCategory.personal,
    this.customTag,
    this.description,
    this.priority,
    this.parentId,
    this.itemType = GoalItemType.goal,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final GoalCategory category;
  final String? customTag;
  final String? description;

  /// 1-based priority (1 = highest). null means no priority set.
  final int? priority;

  /// Links this goal to a parent goal in the next higher tier.
  final String? parentId;
  final GoalItemType itemType;

  Map<String, dynamic> toMap() => {
    'title': title,
    'isCompleted': isCompleted,
    'category': category.name,
    'customTag': customTag,
    'description': description,
    'priority': priority,
    'parentId': parentId,
    'itemType': itemType.name,
  };

  factory Goal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Goal(
      id: doc.id,
      title: d['title'] as String,
      isCompleted: d['isCompleted'] as bool? ?? false,
      category: GoalCategory.values.byName(
        d['category'] as String? ?? 'personal',
      ),
      customTag: d['customTag'] as String?,
      description: d['description'] as String?,
      priority: d['priority'] as int?,
      parentId: d['parentId'] as String?,
      itemType: GoalItemType.values.byName(d['itemType'] as String? ?? 'goal'),
    );
  }

  Goal copyWith({
    bool? isCompleted,
    String? description,
    Object? priority = _sentinel,
    Object? parentId = _sentinel,
    Object? customTag = _sentinel,
    GoalItemType? itemType,
  }) => Goal(
    id: id,
    title: title,
    isCompleted: isCompleted ?? this.isCompleted,
    category: category,
    customTag: customTag == _sentinel ? this.customTag : customTag as String?,
    description: description ?? this.description,
    priority: priority == _sentinel ? this.priority : priority as int?,
    parentId: parentId == _sentinel ? this.parentId : parentId as String?,
    itemType: itemType ?? this.itemType,
  );
}

const _sentinel = Object();

List<Goal> _sortGoals(List<Goal> goals) {
  final sorted = [...goals];
  sorted.sort((a, b) {
    final pa = a.priority ?? 9999;
    final pb = b.priority ?? 9999;
    if (pa != pb) return pa.compareTo(pb);
    return a.title.compareTo(b.title);
  });
  return sorted;
}

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('goals')
      .snapshots()
      .map(
        (snap) => _sortGoals(snap.docs.map((d) => Goal.fromDoc(d)).toList()),
      );
});

final tierGoalsProvider = StreamProvider.family<List<Goal>, GoalTier>((
  ref,
  tier,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection(tier.collection)
      .snapshots()
      .map(
        (snap) => _sortGoals(snap.docs.map((d) => Goal.fromDoc(d)).toList()),
      );
});

final goalsRepoProvider = Provider<GoalsRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return GoalsRepository(user.uid);
});

final tierGoalsRepoProvider = Provider.family<GoalsRepository?, GoalTier>((
  ref,
  tier,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return GoalsRepository(user.uid, tier.collection);
});

class GoalsRepository {
  GoalsRepository(this._uid, [this._collection = 'goals']);

  final String _uid;
  final String _collection;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection(_collection);

  Future<String> add({
    required String title,
    required GoalCategory category,
    String? customTag,
    String? description,
    int? priority,
    String? parentId,
    GoalItemType itemType = GoalItemType.goal,
  }) async {
    final id = _uuid.v4();
    final goal = Goal(
      id: id,
      title: title,
      category: category,
      customTag: customTag,
      description: description,
      priority: priority,
      parentId: parentId,
      itemType: itemType,
    );
    await _col.doc(id).set(goal.toMap());
    return id;
  }

  Future<void> update(Goal goal) =>
      _col.doc(goal.id).set(goal.toMap(), SetOptions(merge: true));

  Future<void> toggle(String id, bool current) =>
      _col.doc(id).update({'isCompleted': !current});

  Future<void> remove(String id) => _col.doc(id).delete();
}

/// Toggles [goal] in [tier] and cascades completion upward:
/// if all siblings under the same parent are now done, the parent is also completed.
Future<void> cascadeToggle({
  required Goal goal,
  required GoalTier tier,
  required String uid,
}) async {
  final fs = FirebaseFirestore.instance;
  final newCompleted = !goal.isCompleted;

  await fs
      .collection('users')
      .doc(uid)
      .collection(tier.collection)
      .doc(goal.id)
      .update({'isCompleted': newCompleted});

  if (newCompleted && goal.parentId != null && tier.parent != null) {
    final parentTier = tier.parent!;
    final col = fs.collection('users').doc(uid).collection(tier.collection);
    final siblings = await col
        .where('parentId', isEqualTo: goal.parentId)
        .get();
    final allDone = siblings.docs.every(
      (d) => d.data()['isCompleted'] as bool? ?? false,
    );

    if (allDone) {
      final parentDoc = await fs
          .collection('users')
          .doc(uid)
          .collection(parentTier.collection)
          .doc(goal.parentId!)
          .get();
      if (parentDoc.exists &&
          !(parentDoc.data()!['isCompleted'] as bool? ?? false)) {
        await cascadeToggle(
          goal: Goal.fromDoc(parentDoc),
          tier: parentTier,
          uid: uid,
        );
      }
    }
  } else if (!newCompleted && goal.parentId != null && tier.parent != null) {
    final parentTier = tier.parent!;
    final parentDoc = await fs
        .collection('users')
        .doc(uid)
        .collection(parentTier.collection)
        .doc(goal.parentId!)
        .get();
    if (parentDoc.exists &&
        (parentDoc.data()!['isCompleted'] as bool? ?? false)) {
      await cascadeToggle(
        goal: Goal.fromDoc(parentDoc),
        tier: parentTier,
        uid: uid,
      );
    }
  }
}

/// Deletes [goal] from [tier] and recursively deletes all child goals in the tier below.
Future<void> cascadeRemove({
  required Goal goal,
  required GoalTier tier,
  required String uid,
}) async {
  final fs = FirebaseFirestore.instance;
  final GoalTier? childTier = switch (tier) {
    GoalTier.long => GoalTier.medium,
    GoalTier.medium => GoalTier.short,
    GoalTier.short => null,
  };
  if (childTier != null) {
    final snap = await fs
        .collection('users')
        .doc(uid)
        .collection(childTier.collection)
        .where('parentId', isEqualTo: goal.id)
        .get();
    for (final doc in snap.docs) {
      await cascadeRemove(goal: Goal.fromDoc(doc), tier: childTier, uid: uid);
    }
  }
  await fs
      .collection('users')
      .doc(uid)
      .collection(tier.collection)
      .doc(goal.id)
      .delete();
}
