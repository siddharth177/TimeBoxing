import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/task.dart';

class CarryoverSection extends StatelessWidget {
  const CarryoverSection({
    super.key,
    required this.tasks,
    required this.onAssignAsToday,
    required this.onMarkDone,
  });

  final List<Task> tasks;
  final void Function(Task task, TaskLevel level) onAssignAsToday;
  final void Function(Task task) onMarkDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.orange40.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange40.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.orange40,
                ),
                const SizedBox(width: 6),
                Text(
                  'Carried over from yesterday',
                  style: AppTextStyles.labelMd(color: AppColors.orange40),
                ),
              ],
            ),
          ),
          ...tasks.map(
            (task) => _CarryoverRow(
              task: task,
              onAssignAsToday: onAssignAsToday,
              onMarkDone: onMarkDone,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _CarryoverRow extends StatelessWidget {
  const _CarryoverRow({
    required this.task,
    required this.onAssignAsToday,
    required this.onMarkDone,
  });

  final Task task;
  final void Function(Task task, TaskLevel level) onAssignAsToday;
  final void Function(Task task) onMarkDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 14,
            color: AppColors.orange40,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(task.title, style: AppTextStyles.textMd())),
          const SizedBox(width: 8),
          _AssignChip(
            label: 'Priority',
            color: AppColors.brown60,
            onTap: () => onAssignAsToday(task, TaskLevel.priority),
          ),
          const SizedBox(width: 6),
          _AssignChip(
            label: 'Chore',
            color: AppColors.orange40,
            onTap: () => onAssignAsToday(task, TaskLevel.chore),
          ),
          const SizedBox(width: 6),
          _AssignChip(
            label: 'Done',
            color: AppColors.green60,
            onTap: () => onMarkDone(task),
          ),
        ],
      ),
    );
  }
}

class _AssignChip extends StatelessWidget {
  const _AssignChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label, style: AppTextStyles.labelSm(color: color)),
      ),
    );
  }
}
