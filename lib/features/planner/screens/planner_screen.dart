import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeboxing/core/theme/app_text_styles.dart';
import 'package:timeboxing/features/timeline/providers/timeline_provider.dart';

final _selectedDayProvider = NotifierProvider<_SelectedDayNotifier, DateTime>(
  _SelectedDayNotifier.new,
);

class _SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void set(DateTime day) => state = day;
}

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(timeBlocksProvider).value ?? [];
    final selectedDay = ref.watch(_selectedDayProvider);
    final scheme = Theme.of(context).colorScheme;

    final dayBlocks =
        blocks.where((b) => _sameDay(b.startTime, selectedDay)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final totalMin = dayBlocks.fold<int>(
      0,
      (sum, b) => sum + b.duration.inMinutes,
    );

    final completedCount = dayBlocks.where((b) => b.isCompleted).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsGeometry.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Planner', style: AppTextStyles.heading2xl()),
                      Text(
                        '$completedCount / ${dayBlocks.length} done . ${_fmtDuration(totalMin)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
