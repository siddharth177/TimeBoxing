import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/goal_provider.dart';
import 'goal_form_widgets.dart';

class TierTabStrip extends StatelessWidget {
  const TierTabStrip({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Row(
        children: GoalTier.values.indexed.map((entry) {
          final i = entry.$1;
          final tier = entry.$2;
          final active = controller.index == i;
          return Padding(
            padding: EdgeInsets.only(
              right: i < GoalTier.values.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? scheme.primary : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(100),
                  border: active
                      ? null
                      : Border.all(color: scheme.outlineVariant),
                ), // BoxDecoration
                child: Text(
                  tier.label,
                  style: AppTextStyles.labelSm(
                    color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ), // Text
              ), // AnimatedContainer
            ), // GestureDetector
          ); // Padding
        }).toList(),
      ), // Row
    ); // AnimatedBuilder
  }
}

class GoalPage extends ConsumerStatefulWidget {
  const GoalPage({
    super.key,
    required this.tier,
    required this.onAdd,
    required this.onEdit,
  });

  final GoalTier tier;
  final void Function(String? parentId) onAdd;
  final void Function(Goal goal) onEdit;

  @override
  ConsumerState<GoalPage> createState() => _GoalPageState();

  static Widget _emptyState(ColorScheme scheme, GoalTier tier) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 48, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'No ${tier.label.toLowerCase()} goals yet',
            style: AppTextStyles.headingXs(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            tier.hint,
            style: AppTextStyles.textSm(color: scheme.outlineVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ), // Column
    ), // Padding
  ); // Center
}

class _GoalPageState extends ConsumerState<GoalPage> {
  final _pendingDelete = <String>{};

  void _delete(Goal g, String uid) {
    setState(() => _pendingDelete.add(g.id));
    cascadeRemove(goal: g, tier: widget.tier, uid: uid);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allGoals = ref.watch(tierGoalsProvider(widget.tier));
    final goals =
        allGoals.where((g) => !_pendingDelete.contains(g.id)).value ?? [];
    final uid = ref.read(currentUserProvider)?.uid;

    void doToggle(Goal g) {
      if (uid != null) {
        cascadeToggle(goal: g, tier: widget.tier, uid: uid);
      }
    }

    if (widget.tier == GoalTier.long) {
      if (goals.isEmpty) return GoalPage._emptyState(scheme, widget.tier);
      final mediumGoals =
          ref.watch(tierGoalsProvider(GoalTier.medium)).value ?? [];
      final longChildMap = <String, List<Goal>>{};
      for (final mg in mediumGoals) {
        if (mg.parentId != null) (longChildMap[mg.parentId!] ??= []).add(mg);
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: goals.length + 1,
        itemBuilder: (_, i) {
          if (i == goals.length) {
            return _AddGoalTile(onTap: () => widget.onAdd(null));
          }
          final g = goals[i];
          return _GoalTile(
            goal: g,
            tier: widget.tier,
            children: longChildMap[g.id] ?? [],
            onToggle: () => doToggle(g),
            onDelete: () {
              if (uid != null) _delete(g, uid);
            },
            onTap: () => widget.onEdit(g),
          ); // _GoalTile
        },
      ); // ListView.builder
    }

    final parentTier = widget.tier.parent!;
    final parentGoals = ref.watch(tierGoalsProvider(parentTier)).value ?? [];

    final byParent = <String?, List<Goal>>{};
    for (final g in goals) {
      (byParent[g.parentId] ??= []).add(g);
    }

    if (parentGoals.isEmpty && goals.isEmpty) {
      return GoalPage._emptyState(scheme, widget.tier);
    }

    final Map<String, List<Goal>> childMap;
    if (widget.tier == GoalTier.medium) {
      final shortGoals =
          ref.watch(tierGoalsProvider(GoalTier.short)).value ?? [];
      childMap = {};
      for (final sg in shortGoals) {
        if (sg.parentId != null) (childMap[sg.parentId!] ??= []).add(sg);
      }
    } else {
      childMap = {};
    }

    final sections = <Widget>[];

    for (final parent in parentGoals) {
      final children = byParent[parent.id] ?? [];
      sections.add(
        _GoalGroupSection(
          tier: widget.tier,
          parentPriority: parent.priority,
          parentTitle: parent.title,
          parentCompleted: parent.isCompleted,
          goals: children,
          childMap: childMap,
          onToggle: doToggle,
          onDelete: (g) {
            if (uid != null) _delete(g, uid);
          },
          onAdd: () => widget.onAdd(parent.id),
          onEdit: widget.onEdit,
        ),
      ); // _GoalGroupSection
    }

    final unlinked = byParent[null] ?? [];
    sections.add(
      _GoalGroupSection(
        tier: widget.tier,
        parentPriority: null,
        parentTitle: parentGoals.isEmpty ? null : 'No parent goal',
        parentCompleted: false,
        goals: unlinked,
        childMap: childMap,
        onToggle: doToggle,
        onDelete: (g) {
          if (uid != null) _delete(g, uid);
        },
        onAdd: () => widget.onAdd(null),
        onEdit: widget.onEdit,
      ),
    ); // _GoalGroupSection

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: sections,
    ); // ListView
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.tier,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
    this.children = const [],
  });

  final Goal goal;
  final GoalTier tier;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final List<Goal> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.orange40,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      // Container
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete goal?'),
                content: Text('Delete "${goal.title}"? This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ), // TextButton
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(ctx).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ), // TextButton
                ],
              ), // AlertDialog
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: GestureDetector(
          onTap: onToggle,
          child: Icon(
            goal.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: goal.isCompleted ? AppColors.green60 : scheme.outlineVariant,
          ), // Icon
        ),
        // GestureDetector
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              goal.title,
              style:
                  AppTextStyles.textMd(
                    color: goal.isCompleted
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ).copyWith(
                    decoration: goal.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
            ), // Text
            if (children.isNotEmpty) ...[
              const SizedBox(height: 4),
              _TypeProgressRow(goals: children),
            ],
          ],
        ),
        // Column
        subtitle: goal.description != null
            ? Text(
                goal.description!,
                style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ) // Text
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tier != GoalTier.long) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: goal.itemType.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ), // BoxDecoration
                child: Text(
                  goal.itemType.label,
                  style: AppTextStyles.textXs(color: goal.itemType.color),
                ), // Text
              ), // Container
              if (goal.priority != null) const SizedBox(width: 6),
            ],
            if (goal.priority != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brown60.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ), // BoxDecoration
                child: Text(
                  tierPriorityLabel(tier, goal.priority!),
                  style: AppTextStyles.textXs(color: AppColors.brown60),
                ), // Text
              ), // Container
            ],
            if (tier == GoalTier.long) ...[
              if (goal.priority != null) const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (goal.customTag != null
                              ? AppColors.brown40
                              : goal.category.color)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ), // BoxDecoration
                child: Text(
                  goal.customTag ?? goal.category.label,
                  style: AppTextStyles.textXs(
                    color: goal.customTag != null
                        ? AppColors.brown40
                        : goal.category.color,
                  ),
                ), // Text
              ), // Container
            ],
          ],
        ), // Row
      ), // ListTile
    ); // Dismissible
  }
}

class _GoalGroupSection extends StatelessWidget {
  const _GoalGroupSection({
    required this.tier,
    required this.parentPriority,
    required this.parentTitle,
    required this.parentCompleted,
    required this.goals,
    required this.childMap,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.onEdit,
  });

  final GoalTier tier;
  final int? parentPriority;
  final String? parentTitle;
  final bool parentCompleted;
  final List<Goal> goals;
  final Map<String, List<Goal>> childMap;
  final void Function(Goal) onToggle;
  final void Function(Goal) onDelete;
  final VoidCallback onAdd;
  final void Function(Goal) onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parentTitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Row(
              children: [
                if (parentPriority != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brown60.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ), // BoxDecoration
                    child: Text(
                      tierPriorityLabel(tier.parent!, parentPriority!),
                      style: AppTextStyles.textXs(color: AppColors.brown60),
                    ),
                  ), // Container
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    parentTitle!,
                    style:
                        AppTextStyles.headingXs(
                          color: parentCompleted
                              ? scheme.outlineVariant
                              : scheme.onSurface,
                        ).copyWith(
                          decoration: parentCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ), // Text
                ), // Expanded
              ],
            ), // Row
          ), // Padding
        ...goals.map(
          (g) => _GoalTile(
            goal: g,
            tier: tier,
            children: childMap[g.id] ?? [],
            onToggle: () => onToggle(g),
            onDelete: () => onDelete(g),
            onTap: () => onEdit(g),
          ),
        ), // _GoalTile
        InkWell(
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ), // BoxDecoration
                  child: Icon(
                    Icons.add,
                    size: 13,
                    color: scheme.outlineVariant,
                  ),
                ), // Container
                const SizedBox(width: 12),
                Text(
                  'Add goal',
                  style: AppTextStyles.textSm(color: scheme.outlineVariant),
                ),
              ],
            ), // Row
          ), // Padding
        ), // InkWell
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.18),
          indent: 20,
          endIndent: 20,
        ), // Divider
      ],
    ); // Column
  }
}

class _TypeProgressRow extends StatelessWidget {
  const _TypeProgressRow({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final type in GoalItemType.values) {
      final typed = goals.where((g) => g.itemType == type).toList();
      if (typed.isEmpty) continue;
      final done = typed.where((g) => g.isCompleted).length;
      chips.add(_ProgressPill(type: type, done: done, total: typed.length));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.type,
    required this.done,
    required this.total,
  });

  final GoalItemType type;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final allDone = done == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: allDone ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(100),
      ), // BoxDecoration
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allDone) ...[
            Icon(Icons.check_rounded, size: 10, color: type.color),
            const SizedBox(width: 3),
          ],
          Text(
            '$done/$total ${type.label}${total != 1 ? "s" : ""} ${type.verb}',
            style: AppTextStyles.textXs(color: type.color),
          ), // Text
        ],
      ), // Row
    ); // Container
  }
}

class _AddGoalTile extends StatelessWidget {
  const _AddGoalTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ), // BoxDecoration
              child: Icon(Icons.add, size: 14, color: scheme.outlineVariant),
            ), // Container
            const SizedBox(width: 14),
            Text(
              'Add long-term goal',
              style: AppTextStyles.textMd(color: scheme.outlineVariant),
            ),
          ],
        ), // Row
      ), // Padding
    ); // InkWell
  }
}
