import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/time_block.dart';

class TimeSlotTile extends StatelessWidget {
  const TimeSlotTile({
    super.key,
    required this.block,
    required this.onTap,
    required this.onToggle,
    this.onLongPress,
    this.isCurrentHour = false,
  });

  final TimeBlock block;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;
  final bool isCurrentHour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = block.color ?? scheme.primary;
    final timeFmt = DateFormat('h:mm');
    final isNow = block.isNow;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: isNow ? accent.withValues(alpha: 0.12) : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNow
                ? accent.withValues(alpha: 0.4)
                : scheme.outlineVariant,
            width: isNow ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              height: 64,
              decoration: BoxDecoration(
                color: block.isCompleted ? AppColors.gray20 : accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Time column
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeFmt.format(block.startTime),
                    style: AppTextStyles.textSm(
                      color: scheme.onSurfaceVariant,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeFmt.format(block.endTime),
                    style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            Container(width: 1, height: 40, color: scheme.outlineVariant),
            const SizedBox(width: 14),

            // Title & type badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    block.title,
                    style:
                        AppTextStyles.headingXs(
                          color: block.isCompleted
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ).copyWith(
                          decoration: block.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _TypeBadge(type: block.type, color: accent),
                ],
              ),
            ),

            // Checkbox
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: block.isCompleted
                        ? AppColors.green60
                        : AppColors.transparent,
                    border: Border.all(
                      color: block.isCompleted
                          ? AppColors.green60
                          : scheme.outline,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: block.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.color});

  final TimeBlockType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      TimeBlockType.task => 'Task',
      TimeBlockType.chore => 'Chore',
      TimeBlockType.recurring => 'Recurring',
      TimeBlockType.free => 'Free',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.textXs(color: color, weight: FontWeight.w700),
      ),
    );
  }
}
