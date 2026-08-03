import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeboxing/features/review/screens/review_sheet.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final streak = ref.watch(currentStreakProvider);
    final logsAsync = ref.watch(dailyLogsProvider);
    final logs = logsAsync.value ?? [];
    final hasLoggedToday = logs.any(
      (l) =>
          l.date.year == today.year &&
          l.date.month == today.month &&
          l.date.day == today.day,
    );

    // Guard against flash: only show banner once data has loaded.
    final showWarning = logsAsync is AsyncData && streak > 0 && !hasLoggedToday;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showWarning) _StreakWarningBanner(streak: streak),
          Expanded(child: ReviewSheet(date: today, asScreen: true)),
        ],
      ),
    );
  }
}

class _StreakWarningBanner extends StatelessWidget {
  const _StreakWarningBanner({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orange40.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange40.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$streak-day streak at risk — log today's review to keep it going!",
              style: AppTextStyles.textMd(color: AppColors.orange40),
            ),
          ),
        ],
      ),
    );
  }
}
