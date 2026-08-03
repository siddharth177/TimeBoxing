import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/notification_service.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../goals/providers/goals_provider.dart';
import '../../timeboxing/models/task.dart';
import '../../timeboxing/providers/task_provider.dart';
import '../../timeline/models/time_block.dart';
import '../../timeline/providers/timeline_provider.dart';
import '../models/daily_log.dart';
import '../models/insight.dart';
import '../providers/insight_provider.dart';
import '../providers/review_provider.dart';

class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({super.key, required this.date, this.asScreen = false});

  final DateTime date;
  final bool asScreen;

  static Future<void> show(BuildContext context, {required DateTime date}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ReviewSheet(date: date, asScreen: false),
      );

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

// Task status within the review sheet (overrides persisted value locally
// before the user hits Save, at which point changes are flushed to Firestore).
enum _TaskStatus { done, skipped, pending }

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  final _reflectionCtrl = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  int? _mood;

  // Local overrides: null = use persisted value, otherwise user-set in sheet.
  late final Map<String, _TaskStatus> _statusOverrides;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Task> _priorities(List<Task> tasks) =>
      tasks.where((t) => t.level == TaskLevel.priority).toList();

  List<Task> _chores(List<Task> tasks) =>
      tasks.where((t) => t.level == TaskLevel.chore).toList();

  bool _baseCompleted(Task t, List<TimeBlock> dayBlocks) =>
      t.isCompleted || dayBlocks.any((b) => b.taskId == t.id && b.isCompleted);

  _TaskStatus _statusOf(Task t, List<TimeBlock> dayBlocks) {
    if (_statusOverrides.containsKey(t.id)) return _statusOverrides[t.id]!;
    return _baseCompleted(t, dayBlocks)
        ? _TaskStatus.done
        : _TaskStatus.pending;
  }

  void _cycleStatus(Task t, List<TimeBlock> dayBlocks) {
    HapticFeedback.lightImpact();
    setState(() {
      final cur = _statusOf(t, dayBlocks);
      _statusOverrides[t.id] = switch (cur) {
        _TaskStatus.pending => _TaskStatus.done,
        _TaskStatus.done => _TaskStatus.skipped,
        _TaskStatus.skipped => _TaskStatus.pending,
      };
    });
  }

  int _completedPriorities(List<Task> tasks, List<TimeBlock> dayBlocks) =>
      _priorities(
        tasks,
      ).where((t) => _statusOf(t, dayBlocks) == _TaskStatus.done).length;

  int _completedChores(List<Task> tasks, List<TimeBlock> dayBlocks) => _chores(
    tasks,
  ).where((t) => _statusOf(t, dayBlocks) == _TaskStatus.done).length;

  double _rate(List<Task> tasks, List<TimeBlock> dayBlocks) {
    if (tasks.isEmpty) return 0;
    return (_completedPriorities(tasks, dayBlocks) +
            _completedChores(tasks, dayBlocks)) /
        tasks.length;
  }

  @override
  void initState() {
    super.initState();
    _statusOverrides = {};
  }

  @override
  void dispose() {
    _reflectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final tasks = ref.read(tasksProvider(widget.date)).value ?? [];
      final allBlocks = ref.read(timeBlocksProvider).value ?? [];
      final dayBlocks = allBlocks
          .where((b) => _sameDay(b.startTime, widget.date))
          .toList();

      final repo = ref.read(tasksRepoProvider);
      if (repo != null) {
        for (final t in tasks) {
          final override = _statusOverrides[t.id];
          if (override == null) continue;
          final shouldBeComplete = override == _TaskStatus.done;
          if (shouldBeComplete != t.isCompleted) {
            await repo.toggleComplete(t.id, t.isCompleted);
          }
        }
      }

      final skippedTaskIds = tasks
          .where((t) => _statusOf(t, dayBlocks) == _TaskStatus.skipped)
          .map((t) => t.id)
          .toList();

      final streak = ref.read(currentStreakProvider);
      final log = DailyLog(
        date: widget.date,
        totalTasks: _priorities(tasks).length,
        completedTasks: _completedPriorities(tasks, dayBlocks),
        totalChores: _chores(tasks).length,
        completedChores: _completedChores(tasks, dayBlocks),
        streak: streak + (_rate(tasks, dayBlocks) >= 0.5 ? 1 : 0),
        reflection: _reflectionCtrl.text.trim().isEmpty
            ? null
            : _reflectionCtrl.text.trim(),
        mood: _mood,
        skippedTaskIds: skippedTaskIds,
      );
      await ref.read(reviewRepoProvider)?.saveLog(log);

      unawaited(NotificationService.cancelStreakWarning());

      // Fire AI analysis in background — never blocks save.
      final analysisService = ref.read(reflectionAnalysisServiceProvider);
      if (analysisService != null) {
        final logs = ref.read(dailyLogsProvider).value ?? [];
        final goalTitles = ref
            .read(tierGoalsProvider(GoalTier.long))
            .value
            ?.map((g) => g.title)
            .toList();
        analysisService.shouldAnalyze(logs.length).then((should) {
          if (should) analysisService.analyze(logs, goalTitles: goalTitles);
        });
      }

      if (mounted) {
        if (widget.asScreen) {
          setState(() {
            _saving = false;
            _saved = true;
          });
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _saved = false);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('[ReviewSheet] Save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save review. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final streak = ref.watch(currentStreakProvider);

    final tasks = ref.watch(tasksProvider(widget.date)).value ?? [];
    final allBlocks = ref.watch(timeBlocksProvider).value ?? [];
    final dayBlocks = allBlocks
        .where((b) => _sameDay(b.startTime, widget.date))
        .toList();

    final priorities = _priorities(tasks);
    final chores = _chores(tasks);
    final rate = _rate(tasks, dayBlocks);
    final pct = (rate * 100).round();
    final rateColor = pct >= 80
        ? AppColors.green60
        : pct >= 50
        ? AppColors.orange40
        : scheme.error;

    final content = SingleChildScrollView(
      child: Padding(
        padding: widget.asScreen
            ? const EdgeInsets.fromLTRB(20, 24, 20, 32)
            : EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.asScreen) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray20,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Consumer(
              builder: (ctx, ref, child) {
                final insights = ref.watch(insightsProvider).value ?? [];
                if (insights.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: insights
                        .map(
                          (insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _InsightCard(insight: insight),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),

            Row(
              children: [
                Text('Introspect', style: AppTextStyles.heading2xl()),
                const Spacer(),
                if (streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange40.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$streak day streak',
                          style: AppTextStyles.labelSm(
                            color: AppColors.orange40,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _RingProgress(rate: rate, color: rateColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatRow(
                        icon: Icons.flag_rounded,
                        color: AppColors.brown60,
                        label: 'Priorities',
                        done: _completedPriorities(tasks, dayBlocks),
                        total: priorities.length,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.orange40,
                        label: 'Chores',
                        done: _completedChores(tasks, dayBlocks),
                        total: chores.length,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$pct% complete',
                        style: AppTextStyles.headingSm(color: rateColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (tasks.isNotEmpty) ...[
              Text(
                'Today\'s tasks',
                style: AppTextStyles.labelMd(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              ...[
                if (priorities.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 12,
                          color: AppColors.brown60,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Priorities',
                          style: AppTextStyles.textXs(color: AppColors.brown60),
                        ),
                      ],
                    ),
                  ),
                  ...priorities.map(
                    (t) => _TaskReviewRow(
                      task: t,
                      status: _statusOf(t, dayBlocks),
                      onTap: () => _cycleStatus(t, dayBlocks),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (chores.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 12,
                          color: AppColors.orange40,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Chores',
                          style: AppTextStyles.textXs(
                            color: AppColors.orange40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...chores.map(
                    (t) => _TaskReviewRow(
                      task: t,
                      status: _statusOf(t, dayBlocks),
                      onTap: () => _cycleStatus(t, dayBlocks),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),
            ],

            Text(
              'How did you feel today?',
              style: AppTextStyles.labelMd(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            _MoodPicker(
              selected: _mood,
              onSelect: (v) => setState(() => _mood = _mood == v ? null : v),
            ),
            const SizedBox(height: 20),

            Text(
              'Reflection',
              style: AppTextStyles.labelMd(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reflectionCtrl,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'What went well? What will you do differently tomorrow?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.secondary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TbButton(
              label: _saving
                  ? 'Saving...'
                  : _saved
                  ? 'Saved!'
                  : 'Save Review',
              onPressed: (_saving || _saved) ? null : _save,
            ),

            if (kDebugMode) ...[
              const SizedBox(height: 10),
              TbButton(
                label: 'Test AI Insight',
                variant: TbButtonVariant.outlined,
                onPressed: () async {
                  final svc = ref.read(reflectionAnalysisServiceProvider);
                  if (svc == null) return;
                  final logs = ref.read(dailyLogsProvider).value ?? [];
                  final goalTitles = ref
                      .read(tierGoalsProvider(GoalTier.long))
                      .value
                      ?.map((g) => g.title)
                      .toList();
                  await svc.forceAnalyze(logs, goalTitles: goalTitles);
                },
              ),
            ],
          ],
        ),
      ),
    );

    return content;
  }
}

class _RingProgress extends StatelessWidget {
  const _RingProgress({required this.rate, required this.color});

  final double rate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: rate,
            strokeWidth: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${(rate * 100).round()}%',
            style: AppTextStyles.labelMd(color: color),
          ),
        ],
      ),
    );
  }
}

class _TaskReviewRow extends StatelessWidget {
  const _TaskReviewRow({
    required this.task,
    required this.status,
    required this.onTap,
  });

  final Task task;
  final _TaskStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, iconColor, textDecoration) = switch (status) {
      _TaskStatus.done => (
        Icons.check_circle_rounded,
        AppColors.green60,
        TextDecoration.lineThrough,
      ),
      _TaskStatus.skipped => (
        Icons.remove_circle_outline_rounded,
        scheme.onSurfaceVariant,
        TextDecoration.none,
      ),
      _TaskStatus.pending => (
        Icons.radio_button_unchecked,
        scheme.outline,
        TextDecoration.none,
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                style: AppTextStyles.textSm(
                  color: status == _TaskStatus.skipped
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ).copyWith(decoration: textDecoration),
              ),
            ),
            if (status == _TaskStatus.skipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Skipped',
                  style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatefulWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  static IconData _iconFor(InsightType type) => switch (type) {
    InsightType.overcommitting => Icons.inventory_2_outlined,
    InsightType.choreHeavy => Icons.repeat_rounded,
    InsightType.dayPattern => Icons.calendar_today_outlined,
    InsightType.burnout => Icons.battery_alert_rounded,
    InsightType.timeManagement => Icons.timer_outlined,
    InsightType.reflectionPattern => Icons.chat_bubble_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const accent = AppColors.brown60;

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.insight.headline,
                      style: AppTextStyles.labelMd(color: accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: accent.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),

          if (_expanded && widget.insight.items.isNotEmpty) ...[
            Divider(height: 1, color: accent.withValues(alpha: 0.15)),
            ...widget.insight.items.map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _iconFor(item.type),
                      size: 16,
                      color: accent.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.labelSm(color: accent),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.detail,
                            style: AppTextStyles.textSm(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: AppColors.green60.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.suggestion,
                                  style: AppTextStyles.textSm(
                                    color: AppColors.green60,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.selected, required this.onSelect});

  final int? selected;
  final void Function(int value) onSelect;

  static const _emojis = ['😩', '😕', '😐', '😊', '😄'];
  static const _labels = ['Rough', 'Meh', 'Okay', 'Good', 'Great'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_emojis.length, (i) {
        final value = i + 1;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onSelect(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brown60.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppColors.brown60.withValues(alpha: 0.40))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _emojis[i],
                  style: TextStyle(fontSize: isSelected ? 28 : 24),
                ),
                const SizedBox(height: 2),
                Text(
                  _labels[i],
                  style: AppTextStyles.textXs(
                    color: isSelected
                        ? AppColors.brown60
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.done,
    required this.total,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int done, total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          '$done / $total',
          style: AppTextStyles.textSm(color: scheme.onSurface),
        ),
      ],
    );
  }
}
