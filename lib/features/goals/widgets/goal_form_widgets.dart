import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/goal_provider.dart';
import '../screens/ai_goal_plan_sheet.dart';
import '../services/ai_goal_service.dart';

String tierPriorityLabel(GoalTier tier, int p) => switch (tier) {
  GoalTier.long => 'L$p',
  GoalTier.medium => 'M$p',
  GoalTier.short => 'S$p',
};

Color priorityColor(int p) => switch (p) {
  1 => AppColors.orange40,
  2 => AppColors.yellow40,
  3 => AppColors.green60,
  4 => AppColors.blue60,
  _ => AppColors.purple60,
};

class GoalSheets {
  static void showEdit(
      BuildContext context,
      WidgetRef ref,
      GoalTier tier,
      Goal goal,
      ) {
    final ctrl = TextEditingController(text: goal.title);
    final descCtrl = TextEditingController(text: goal.description ?? '');
    final customTagCtrl = TextEditingController();
    final showDesc = ref.read(appSettingsProvider).showDescriptions;

    GoalCategory? selectedCat = goal.customTag == null ? goal.category : null;
    String? customTag = goal.customTag;
    bool showTagInput = false;
    String? selectedParentId = goal.parentId;
    int prioritySlots = goal.priority ?? 1;
    int selectedPriority = goal.priority ?? 1;
    GoalItemType selectedType = goal.itemType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final scheme = Theme.of(ctx).colorScheme;
          final parentTier = tier.parent;
          final parentGoals = parentTier != null
              ? (ref.read(tierGoalsProvider(parentTier)).value ?? [])
              : <Goal>[];
          final allGoals = ref.read(tierGoalsProvider(tier)).value ?? [];
          final takenPriorities = allGoals
              .where((g) => g.id != goal.id)
              .map((g) => g.priority)
              .whereType<int>()
              .toSet();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray20,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Edit ${tier.label} Goal',
                  style: AppTextStyles.headingMd(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'What do you want to achieve?',
                  ),
                ),
                if (showDesc) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                    ),
                  ),
                ],
                if (tier != GoalTier.long) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Type',
                        style: AppTextStyles.textSm(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final t in GoalItemType.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _SheetChip(
                                    label: t.label,
                                    selected: selectedType == t,
                                    accentColor: t.color,
                                    onTap: () => setSt(() => selectedType = t),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (tier == GoalTier.long) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final cat in GoalCategory.values) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _SheetChip(
                              label: cat.label,
                              selected: selectedCat == cat && customTag == null,
                              accentColor: cat.color,
                              onTap: () => setSt(() {
                                selectedCat = cat;
                                customTag = null;
                                showTagInput = false;
                              }),
                            ),
                          ),
                        ],
                        if (customTag != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _SheetChip(
                              label: customTag!,
                              selected: selectedCat == null,
                              accentColor: AppColors.brown40,
                              onTap: () => setSt(() => selectedCat = null),
                              onDelete: () => setSt(() {
                                customTag = null;
                                selectedCat = GoalCategory.personal;
                              }),
                            ),
                          ),
                        if (showTagInput)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 36,
                                child: TextField(
                                  controller: customTagCtrl,
                                  autofocus: false,
                                  decoration: const InputDecoration(
                                    hintText: 'Tag name',
                                    isDense: true,
                                    contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      setSt(() {
                                        customTag = val.trim();
                                        selectedCat = null;
                                        showTagInput = false;
                                        customTagCtrl.clear();
                                      });
                                    } else {
                                      setSt(() => showTagInput = false);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  final val = customTagCtrl.text.trim();
                                  if (val.isNotEmpty) {
                                    setSt(() {
                                      customTag = val;
                                      selectedCat = null;
                                      showTagInput = false;
                                      customTagCtrl.clear();
                                    });
                                  } else {
                                    setSt(() => showTagInput = false);
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: AppColors.green60,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      size: 16, color: AppColors.white),
                                ),
                              ),
                            ],
                          )
                        else if (customTag == null)
                          GestureDetector(
                            onTap: () => setSt(() {
                              showTagInput = true;
                              selectedCat = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: scheme.outline.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      size: 14, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tag',
                                    style: AppTextStyles.textSm(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else if (parentGoals.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Links to',
                        style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _ParentChip(
                                label: 'None',
                                selected: selectedParentId == null,
                                onTap: () => setSt(() {
                                  selectedParentId = null;
                                  prioritySlots = -1;
                                  selectedPriority = -1;
                                }),
                              ),
                              for (final pg in parentGoals) ...[
                                const SizedBox(width: 6),
                                _ParentChip(
                                  label: pg.priority != null
                                      ? '${tierPriorityLabel(tier.parent!, pg.priority!)}: ${pg.title}'
                                      : pg.title,
                                  selected: selectedParentId == pg.id,
                                  onTap: () => setSt(() {
                                    selectedParentId = pg.id;
                                    prioritySlots = -1;
                                    selectedPriority = -1;
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Priority',
                      style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int p = 1; p <= prioritySlots; p++) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _SheetChip(
                                  label: tierPriorityLabel(tier, p),
                                  selected: selectedPriority == p,
                                  accentColor: priorityColor(p),
                                  disabled: takenPriorities.contains(p),
                                  onTap: () => setSt(() => selectedPriority = p),
                                ),
                              ),
                            ],
                            GestureDetector(
                              onTap: () => setSt(() {
                                prioritySlots++;
                                selectedPriority = prioritySlots;
                              }),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.outline.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(Icons.add,
                                    size: 16, color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        final desc = descCtrl.text.trim();
                        ref.read(tierGoalsRepoProvider(tier))?.update(
                          goal.copyWith(
                            title: ctrl.text.trim(),
                            isCompleted: goal.isCompleted,
                            category: selectedCat ?? GoalCategory.personal,
                            customTag: customTag,
                            description: desc.isEmpty ? null : desc,
                            priority: selectedPriority > 0 ? selectedPriority : 0,
                            parentId: selectedParentId,
                            itemType: selectedType,
                          ),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void showAdd(
      BuildContext context,
      WidgetRef ref,
      GoalTier tier,
      {String? parentId}
      ) {
    final ctrl = TextEditingController();
    final descCtrl = TextEditingController();
    final customTagCtrl = TextEditingController();
    final showDesc = ref.read(appSettingsProvider).showDescriptions;

    GoalCategory? selectedCat = tier == GoalTier.long ? GoalCategory.personal : null;
    String? customTag;
    bool showTagInput = false;
    String? selectedParentId = parentId;
    int prioritySlots = -1;
    int selectedPriority = -1;
    GoalItemType selectedType = GoalItemType.goal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final scheme = Theme.of(ctx).colorScheme;
          final parentTier = tier.parent;
          final parentGoals = parentTier != null
              ? (ref.read(tierGoalsProvider(parentTier)).value ?? [])
              : <Goal>[];
          final allGoals = ref.read(tierGoalsProvider(tier)).value ?? [];
          final takenPriorities = allGoals.map((g) => g.priority).whereType<int>().toSet();

          if (prioritySlots == -1) {
            final maxExisting = allGoals.isEmpty
                ? 0
                : allGoals
                .map((g) => g.priority ?? 0)
                .reduce((a, b) => a > b ? a : b);
            prioritySlots = maxExisting + 1;
            selectedPriority = maxExisting + 1;
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray20,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'New ${tier.label} Goal',
                  style: AppTextStyles.headingMd(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'What do you want to achieve?',
                  ),
                ),
                if (showDesc) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                    ),
                  ),
                ],
                if (tier != GoalTier.long) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Type',
                        style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final t in GoalItemType.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _SheetChip(
                                    label: t.label,
                                    selected: selectedType == t,
                                    accentColor: t.color,
                                    onTap: () => setSt(() => selectedType = t),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (tier == GoalTier.long) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final cat in GoalCategory.values) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _SheetChip(
                              label: cat.label,
                              selected: selectedCat == cat && customTag == null,
                              accentColor: cat.color,
                              onTap: () => setSt(() {
                                selectedCat = cat;
                                customTag = null;
                                showTagInput = false;
                              }),
                            ),
                          ),
                        ],
                        if (customTag != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _SheetChip(
                              label: customTag!,
                              selected: selectedCat == null,
                              accentColor: AppColors.brown40,
                              onTap: () => setSt(() => selectedCat = null),
                              onDelete: () => setSt(() {
                                customTag = null;
                                selectedCat = GoalCategory.personal;
                              }),
                            ),
                          ),
                        if (showTagInput)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 36,
                                child: TextField(
                                  controller: customTagCtrl,
                                  autofocus: false,
                                  decoration: InputDecoration(
                                    hintText: 'Tag name',
                                    isDense: true,
                                    contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      setSt(() {
                                        customTag = val.trim();
                                        selectedCat = null;
                                        showTagInput = false;
                                        customTagCtrl.clear();
                                      });
                                    } else {
                                      setSt(() => showTagInput = false);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  final val = customTagCtrl.text.trim();
                                  if (val.isNotEmpty) {
                                    setSt(() {
                                      customTag = val;
                                      selectedCat = null;
                                      showTagInput = false;
                                      customTagCtrl.clear();
                                    });
                                  } else {
                                    setSt(() => showTagInput = false);
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: AppColors.green60,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      size: 16, color: AppColors.white),
                                ),
                              ),
                            ],
                          )
                        else if (customTag == null)
                          GestureDetector(
                            onTap: () => setSt(() {
                              showTagInput = true;
                              selectedCat = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: scheme.outline.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      size: 14, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tag',
                                    style: AppTextStyles.textSm(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else if (parentGoals.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Links to',
                        style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _ParentChip(
                                label: 'None',
                                selected: selectedParentId == null,
                                onTap: () => setSt(() => selectedParentId = null),
                              ),
                              for (final pg in parentGoals) ...[
                                const SizedBox(width: 6),
                                _ParentChip(
                                  label: pg.priority != null
                                      ? '${tierPriorityLabel(tier.parent!, pg.priority!)}: ${pg.title}'
                                      : pg.title,
                                  selected: selectedParentId == pg.id,
                                  onTap: () => setSt(() => selectedParentId = pg.id),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Priority',
                      style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int p = 1; p <= prioritySlots; p++) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _SheetChip(
                                  label: tierPriorityLabel(tier, p),
                                  selected: selectedPriority == p,
                                  accentColor: priorityColor(p),
                                  disabled: takenPriorities.contains(p),
                                  onTap: () => setSt(() => selectedPriority = p),
                                ),
                              ),
                            ],
                            GestureDetector(
                              onTap: () => setSt(() {
                                prioritySlots++;
                                selectedPriority = prioritySlots;
                              }),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.outline.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(Icons.add,
                                    size: 16, color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _AiPlanButton(
                  enabled: true,
                  onTap: () async {
                    final title = ctrl.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a goal title first.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final plan = await AiGoalService.decompose(
                      title: title,
                      description: descCtrl.text.trim(),
                      tier: tier,
                      category: (selectedCat?.label ?? customTag ?? 'Personal'),
                    );

                    if (plan == null) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('AI planning failed. Try again.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }

                    if (ctx.mounted) {
                      await showModalBottomSheet<void>(
                        context: ctx,
                        isScrollControlled: true,
                        builder: (_) => AiGoalPlanSheet(
                          plan: plan,
                          tier: tier,
                          goalTitle: title,
                          goalDescription: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          category: selectedCat?.label ?? customTag ?? 'Personal',
                          onConfirm: (confirmed) {
                            final desc = descCtrl.text.trim();
                            final rootRepo = ref.read(tierGoalsRepoProvider(tier));
                            rootRepo?.add(
                              title: title,
                              category: selectedCat ?? GoalCategory.personal,
                              customTag: customTag,
                              description: desc.isEmpty ? null : desc,
                              priority: selectedPriority > 0 ? selectedPriority : 1,
                              parentId: selectedParentId,
                            ).then((_) {});

                            _confirmAiPlan(
                              ref: ref,
                              plan: confirmed,
                              tier: tier,
                              parentId: rootRepo?.id,
                              category: selectedCat ?? GoalCategory.personal,
                              customTag: customTag,
                            );
                          },
                        ),
                      );

                      if (ctx.mounted) Navigator.of(ctx).pop();
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        final desc = descCtrl.text.trim();
                        ref.read(tierGoalsRepoProvider(tier))?.add(
                          title: ctrl.text.trim(),
                          category: selectedCat ?? GoalCategory.personal,
                          customTag: customTag,
                          description: desc.isEmpty ? null : desc,
                          priority: selectedPriority > 0 ? selectedPriority : 1,
                          parentId: selectedParentId,
                          itemType: selectedType,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add Goal'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> _confirmAiPlan({
    required WidgetRef ref,
    required AiGoalPlan plan,
    required GoalTier tier,
    required String? parentId,
    required GoalCategory category,
    String? customTag,
  }) async {
    final medRepo = ref.read(tierGoalsRepoProvider(GoalTier.medium));
    final shortRepo = ref.read(tierGoalsRepoProvider(GoalTier.short));

    if (tier == GoalTier.long) {
      for (final mg in plan.mediumGoals) {
        if (mg.title.isEmpty) continue;
        await medRepo?.add(
          title: mg.title,
          category: category,
          customTag: customTag,
          description: mg.description.isEmpty ? null : mg.description,
          priority: selectedPriority > 0 ? selectedPriority : 1, // Error in source
          parentId: parentId,
          itemType: GoalItemType.milestone,
        );

        for (final sg in mg.shortGoals) {
          if (sg.title.isEmpty) continue;
          await shortRepo?.add(
            title: sg.title,
            category: category,
            customTag: customTag,
            parentId: parentId, // Logic should handle new med goal ID
            itemType: sg.type,
          );
        }
      }
    }

    if (tier == GoalTier.medium) {
      for (final sg in plan.shortGoals) {
        if (sg.title.isEmpty) continue;
        await shortRepo?.add(
          title: sg.title,
          category: category,
          customTag: customTag,
          parentId: parentId,
          itemType: sg.type,
        );
      }
    }
  }
}

class _ParentChip extends StatelessWidget {
  const _ParentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brown60.withValues(alpha: 0.15)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? AppColors.brown60
                : scheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.textSm(
            color: selected ? AppColors.brown60 : scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    this.onDelete,
    this.disabled = false,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.18)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? accentColor : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected && onDelete == null && !disabled) ...[
              Icon(Icons.check_rounded, size: 12, color: accentColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.textSm(
                color: disabled
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                    : selected
                    ? accentColor
                    : scheme.onSurfaceVariant,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close_rounded, size: 12, color: accentColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiPlanButton extends StatefulWidget {
  const _AiPlanButton({required this.enabled, required this.onTap});

  final bool enabled;
  final Future<void> Function() onTap;

  @override
  State<_AiPlanButton> createState() => _AiPlanButtonState();
}

class _AiPlanButtonState extends State<_AiPlanButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: (_loading || !widget.enabled)
          ? null
          : () async {
        setState(() => _loading = true);
        try {
          await widget.onTap();
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
      icon: _loading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: scheme.primary,
        ),
      )
          : const Text('✨', style: TextStyle(fontSize: 14)),
      label: Text(
        _loading ? 'Planning...' : 'Plan with AI',
        style: AppTextStyles.labelLg(color: scheme.primary),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
        shape: const StadiumBorder(),
      ),
    );
  }
}