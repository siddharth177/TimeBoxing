import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tb_button.dart';
import '../providers/goals_provider.dart';
import '../services/ai_goal_service.dart';

class AiGoalPlanSheet extends StatefulWidget {
  const AiGoalPlanSheet({
    super.key,
    required this.plan,
    required this.tier,
    required this.onConfirm,
    required this.goalTitle,
    this.goalDescription,
    required this.category,
  });

  final AiGoalPlan plan;
  final GoalTier tier;
  final void Function(AiGoalPlan plan) onConfirm;
  final String goalTitle;
  final String? goalDescription;
  final String category;

  @override
  State<AiGoalPlanSheet> createState() => _AiGoalPlanSheetState();
}

class _AiGoalPlanSheetState extends State<AiGoalPlanSheet> {
  late AiGoalPlan _plan;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _plan = _deepCopy(widget.plan, widget.tier);
  }

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      final newPlan = await AiGoalService.decompose(
        title: widget.goalTitle,
        description: widget.goalDescription,
        tier: widget.tier,
        category: widget.category,
      );
      if (!mounted) return;
      if (newPlan != null) {
        setState(() => _plan = _deepCopy(newPlan, widget.tier));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regeneration failed – try again.'),
            behavior: SnackBarBehavior.floating,
          ), // SnackBar
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  AiGoalPlan _deepCopy(AiGoalPlan p, GoalTier tier) {
    return AiGoalPlan(
      mediumGoals: p.mediumGoals
          .map(
            (m) => AiMediumGoal(
              title: m.title,
              shortGoals: m.shortGoals
                  .map(
                    (s) => AiShortGoal(
                      title: s.title,
                      type: s.type,
                      tasks: List<String>.from(s.tasks),
                    ),
                  ) // AiShortGoal
                  .toList(),
            ),
          ) // AiMediumGoal
          .toList(),
      shortGoals: p.shortGoals
          .map(
            (s) => AiShortGoal(
              title: s.title,
              type: s.type,
              tasks: List<String>.from(s.tasks),
            ),
          ) // AiShortGoal
          .toList(),
      tasks: List<String>.from(p.tasks),
    ); // AiGoalPlan
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray20,
                borderRadius: BorderRadius.circular(2),
              ), // BoxDecoration
            ), // Container
          ), // Padding
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Plan Proposal',
                        style: AppTextStyles.headingSm(),
                      ),
                      Text(
                        'Review and edit before confirming.',
                        style: AppTextStyles.textSm(
                          color: scheme.onSurfaceVariant,
                        ),
                      ), // Text
                    ],
                  ), // Column
                ), // Expanded
                const SizedBox(width: 8),
                _regenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) // SizedBox
                    : IconButton(
                        tooltip: 'Regenerate plan',
                        onPressed: _regenerate,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        color: scheme.onSurfaceVariant,
                      ), // IconButton
              ],
            ), // Row
          ), // Padding
          const SizedBox(height: 8),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: _buildContent(scheme),
            ), // ListView
          ), // Expanded
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TbButton(
                    label: 'Discard',
                    variant: TbButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ), // TbButton
                ), // Expanded
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TbButton(
                    label: 'Confirm Plan',
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onConfirm(_plan);
                    },
                  ), // TbButton
                ), // Expanded
              ],
            ), // Row
          ), // Padding
        ],
      ), // Column
    ); // DraggableScrollableSheet
  }

  List<Widget> _buildContent(ColorScheme scheme) {
    final tier = widget.tier;

    if (tier == GoalTier.long) {
      final items = <Widget>[];
      for (var mi = 0; mi < _plan.mediumGoals.length; mi++) {
        final mg = _plan.mediumGoals[mi];
        items.add(
          _SectionHeader(
            label: 'Medium-term goal ${mi + 1}',
            color: AppColors.orange40,
          ),
        );
        items.add(
          _EditableItem(
            value: mg.title,
            indent: 0,
            color: AppColors.orange40,
            icon: Icons.trending_up_rounded,
            onChanged: (v) => setState(() => mg.title = v),
            onDelete: () => setState(() => _plan.mediumGoals.removeAt(mi)),
          ),
        );
        for (var si = 0; si < mg.shortGoals.length; si++) {
          final sg = mg.shortGoals[si];
          items.add(
            _EditableItem(
              value: sg.title,
              indent: 1,
              color: AppColors.blue60,
              icon: Icons.flag_outlined,
              onChanged: (v) => setState(() => sg.title = v),
              onDelete: () => setState(() => mg.shortGoals.removeAt(si)),
            ),
          );
          for (var ti = 0; ti < sg.tasks.length; ti++) {
            items.add(
              _EditableItem(
                value: sg.tasks[ti],
                indent: 2,
                color: AppColors.green60,
                icon: Icons.check_circle_outline_rounded,
                onChanged: (v) => setState(() => sg.tasks[ti] = v),
                onDelete: () => setState(() => sg.tasks.removeAt(ti)),
              ),
            );
          }
        }
        items.add(const SizedBox(height: 8));
      }
      return items;
    }

    if (tier == GoalTier.medium) {
      final items = <Widget>[];
      items.add(
        _SectionHeader(label: 'Short-term milestones', color: AppColors.blue60),
      );
      for (var si = 0; si < _plan.shortGoals.length; si++) {
        final sg = _plan.shortGoals[si];
        items.add(
          _EditableItem(
            value: sg.title,
            indent: 0,
            color: AppColors.blue60,
            icon: Icons.flag_outlined,
            onChanged: (v) => setState(() => sg.title = v),
            onDelete: () => setState(() => _plan.shortGoals.removeAt(si)),
          ),
        );
        for (var ti = 0; ti < sg.tasks.length; ti++) {
          items.add(
            _EditableItem(
              value: sg.tasks[ti],
              indent: 1,
              color: AppColors.green60,
              icon: Icons.check_circle_outline_rounded,
              onChanged: (v) => setState(() => sg.tasks[ti] = v),
              onDelete: () => setState(() => sg.tasks.removeAt(ti)),
            ),
          );
        }
      }
      return items;
    }

    final items = <Widget>[
      _SectionHeader(label: 'Priority tasks', color: AppColors.green60),
    ];
    for (var ti = 0; ti < _plan.tasks.length; ti++) {
      items.add(
        _EditableItem(
          value: _plan.tasks[ti],
          indent: 0,
          color: AppColors.green60,
          icon: Icons.check_circle_outline_rounded,
          onChanged: (v) => setState(() => _plan.tasks[ti] = v),
          onDelete: () => setState(() => _plan.tasks.removeAt(ti)),
        ),
      );
    }
    return items;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm(color: color),
      ), // Text
    ); // Padding
  }
}

class _EditableItem extends StatefulWidget {
  const _EditableItem({
    required this.value,
    required this.indent,
    required this.color,
    required this.icon,
    required this.onChanged,
    required this.onDelete,
  });

  final String value;
  final int indent;
  final Color color;
  final IconData icon;
  final void Function(String) onChanged;
  final VoidCallback onDelete;

  @override
  State<_EditableItem> createState() => _EditableItemState();
}

class _EditableItemState extends State<_EditableItem> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: widget.indent * 20.0, bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _editing
                ? widget.color.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: _editing
            ? Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.textMd(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (v) {
                        widget.onChanged(
                          v.trim().isEmpty ? widget.value : v.trim(),
                        );
                        setState(() {
                          _editing = false;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    color: widget.color,
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      widget.onChanged(v.isEmpty ? widget.value : v);
                      setState(() => _editing = false);
                    },
                  ), // IconButton
                ],
              ) // Row
            : ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                leading: Icon(widget.icon, size: 16, color: widget.color),
                // Icon
                title: Text(_ctrl.text, style: AppTextStyles.textMd()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _editing = true),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ), // Icon
                    ), // GestureDetector
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.red,
                      ), // Icon
                    ), // GestureDetector
                  ],
                ), // Row
              ), // ListTile
      ), // Container
    ); // Padding
  }
}
