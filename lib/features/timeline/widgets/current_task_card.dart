import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/timeline_provider.dart';

class CurrentTaskCard extends ConsumerWidget {
  const CurrentTaskCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final block = ref.watch(currentOrNextBlockProvider);
    if (block == null) return const _EmptyCard();

    final isNow = block.isNow;
    final scheme = Theme.of(context).colorScheme;
    final accent = block.color ?? scheme.primary;
    final timeFmt = DateFormat('h:mm a');
    final remaining = block.endTime.difference(DateTime.now());
    final total = block.endTime.difference(block.startTime);
    final progress = isNow
        ? 1 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isNow ? 'Now' : 'Up next',
                  style: AppTextStyles.labelSm(color: AppColors.white),
                ),
              ),
              const Spacer(),
              Text(
                '${timeFmt.format(block.startTime)} – ${timeFmt.format(block.endTime)}',
                style: AppTextStyles.textSm(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(block.title, style: AppTextStyles.headingMd()),
          if (isNow) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: accent.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(accent),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatRemaining(remaining),
                  style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'Done';
    if (d.inHours >= 1)
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m left';
    return '${d.inMinutes}m left';
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.green10,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.green60,
          size: 28,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All done for today!',
              style: AppTextStyles.headingXs(color: AppColors.green80),
            ),
            const SizedBox(height: 2),
            Text(
              'No more tasks scheduled.',
              style: AppTextStyles.textSm(color: AppColors.green60),
            ),
          ],
        ),
      ],
    ),
  );
}
