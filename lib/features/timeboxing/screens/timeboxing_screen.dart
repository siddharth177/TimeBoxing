import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../goals/providers/goal_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../timeline/models/time_block.dart';
import '../../timeline/providers/timeline_provider.dart';
import '../../timeline/widgets/add_block_sheet.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/backlog_section.dart';
import '../widgets/carryover_section.dart';
import '../widgets/schedule_section.dart';

class TimeboxingScreen extends ConsumerWidget {
  const TimeboxingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(timeboxingDayProvider);
    final tasksAsync = ref.watch(tasksProvider(selectedDay));
    final tasks = tasksAsync.value ?? [];
    final allBlocks = ref.watch(timeBlocksProvider).value ?? [];
    final settings = ref.watch(appSettingsProvider);

    final priorities =
        tasks.where((t) => t.level == TaskLevel.priority).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final chores = tasks.where((t) => t.level == TaskLevel.chore).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final dayBlocks =
        allBlocks.where((b) => _sameDay(b.startTime, selectedDay)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final allChoresDone = _allTasksScheduled(chores, dayBlocks);
    final shortTermGoals =
        ref.watch(tierGoalsProvider(GoalTier.short)).value ?? [];
    final tasksRepo = ref.watch(tasksRepoProvider);
    final blocksRepo = ref.watch(timeBlocksRepoProvider);

    final isToday = _sameDay(selectedDay, DateTime.now());
    final isPast = !isToday && selectedDay.isBefore(DateTime.now());

    const lookbackDays = 7;
    final carryover = <Task>[];
    if (isToday) {
      for (var i = 1; i <= lookbackDays; i++) {
        final pastDay = selectedDay.subtract(Duration(days: i));
        final pastTasks = ref.watch(tasksProvider(pastDay)).value ?? [];
        final pastBlocks = allBlocks
            .where((b) => _sameDay(b.startTime, pastDay))
            .toList();
        carryover.addAll(
          pastTasks.where(
            (t) =>
                !t.isCompleted &&
                !pastBlocks.any((b) => b.taskId == t.id && b.isCompleted),
          ),
        );
      }
    }

    final isTablet = TbBreakpoints.isTablet(context);

    final backlogSection = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          BacklogSection(
            label: 'Priorities',
            icon: Icons.flag_rounded,
            accentColor: settings.colorForPriority(0),
            slotColors: List.generate(
              settings.maxPriorities,
              settings.colorForPriority,
            ),
            tasks: priorities,
            maxSlots: settings.maxPriorities,
            dayBlocks: dayBlocks,
            isLocked: isPast || chores.isEmpty || !allChoresDone,
            lockMessage: isPast
                ? 'Past days are read-only.'
                : chores.isEmpty
                ? 'Add at least one chore first to unlock priorities.'
                : null,
            showDescriptions: settings.showDescriptions,
            linkableGoals: shortTermGoals,
            onAddTask:
                (title, notes, isRec, recType, recDays, remOff, goalId) =>
                    _addTask(
                      ref,
                      tasksRepo,
                      title,
                      TaskLevel.priority,
                      priorities.length,
                      selectedDay,
                      notes: notes,
                      isRecurring: isRec,
                      recurrenceType: recType,
                      recurrenceDays: recDays,
                      reminderOffsetMinutes: remOff,
                      goalId: goalId,
                    ),
            onEditTask: (t) => tasksRepo?.update(t),
            onDeleteTask: (t) => tasksRepo?.delete(t.id),
            onAssignTime: (t) => AssignTimeSheet.show(
              context,
              task: t,
              date: selectedDay,
              blocksRepo: blocksRepo,
            ),
            onToggleComplete: (t) =>
                tasksRepo?.toggleComplete(t.id, t.isCompleted),
          ),
          const SizedBox(height: 12),
          BacklogSection(
            label: 'Chores',
            icon: Icons.repeat_rounded,
            accentColor: settings.colorForChore(0),
            slotColors: List.generate(
              settings.maxChores,
              settings.colorForChore,
            ),
            tasks: chores,
            maxSlots: settings.maxChores,
            dayBlocks: dayBlocks,
            isLocked: isPast,
            lockMessage: isPast ? 'Past days are read-only.' : null,
            showDescriptions: settings.showDescriptions,
            onAddTask:
                (title, notes, isRec, recType, recDays, remOff, goalId) =>
                    _addTask(
                      ref,
                      tasksRepo,
                      title,
                      TaskLevel.chore,
                      chores.length,
                      selectedDay,
                      notes: notes,
                      isRecurring: isRec,
                      recurrenceType: recType,
                      recurrenceDays: recDays,
                      reminderOffsetMinutes: remOff,
                    ),
            onEditTask: (t) => tasksRepo?.update(t),
            onDeleteTask: (t) => tasksRepo?.delete(t.id),
            onAssignTime: (t) => AssignTimeSheet.show(
              context,
              task: t,
              date: selectedDay,
              blocksRepo: blocksRepo,
            ),
            onToggleComplete: (t) =>
                tasksRepo?.toggleComplete(t.id, t.isCompleted),
          ),
        ],
      ),
    );

    final schedulePane = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScheduleHeader(dayBlocks: dayBlocks),
        ScheduleTimeline(
          day: selectedDay,
          dayBlocks: dayBlocks,
          priorities: priorities,
          chores: chores,
          startHour: settings.dayStartHour,
          endHour: settings.dayEndHour,
          snapMinutes: settings.snapMinutes,
          blocksRepo: blocksRepo,
        ),
        const SizedBox(height: 100),
      ],
    );

    final fab = isPast
        ? null
        : Tooltip(
            message: 'Add a free block or impromptu task',
            child: FloatingActionButton(
              heroTag: 'fab-timebox',
              onPressed: () =>
                  AddBlockSheet.show(context, initialDate: selectedDay),
              backgroundColor: AppColors.green60,
              child: const Icon(Icons.add_rounded, color: AppColors.white),
            ),
          );

    if (isTablet) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        floatingActionButton: fab,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: TbBreakpoints.sidebarWidth,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Header(day: selectedDay, dayBlocks: dayBlocks),
                    _WeekStrip(selected: selectedDay),
                    const SizedBox(height: 12),
                    if (carryover.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: CarryoverSection(
                          tasks: carryover,
                          onAssignAsToday: (task, level) {
                            _addTask(
                              ref,
                              tasksRepo,
                              task.title,
                              level,
                              level == TaskLevel.priority
                                  ? priorities.length
                                  : chores.length,
                              selectedDay,
                              notes: task.notes,
                            );
                            tasksRepo?.toggleComplete(
                              task.id,
                              task.isCompleted,
                            );
                          },
                          onMarkDone: (task) => tasksRepo?.toggleComplete(
                            task.id,
                            task.isCompleted,
                          ),
                        ),
                      ),
                    backlogSection,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: SingleChildScrollView(child: schedulePane)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(day: selectedDay, dayBlocks: dayBlocks),
            ),
            SliverToBoxAdapter(child: _WeekStrip(selected: selectedDay)),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (carryover.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: CarryoverSection(
                    tasks: carryover,
                    onAssignAsToday: (task, level) {
                      _addTask(
                        ref,
                        tasksRepo,
                        task.title,
                        level,
                        level == TaskLevel.priority
                            ? priorities.length
                            : chores.length,
                        selectedDay,
                        notes: task.notes,
                      );
                      tasksRepo?.toggleComplete(task.id, task.isCompleted);
                    },
                    onMarkDone: (task) =>
                        tasksRepo?.toggleComplete(task.id, task.isCompleted),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: backlogSection),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: schedulePane),
          ],
        ),
      ),
      floatingActionButton: fab,
    );
  }

  void _addTask(
    WidgetRef ref,
    TasksRepository? repo,
    String title,
    TaskLevel level,
    int order,
    DateTime date, {
    String? notes,
    bool isRecurring = false,
    RecurrenceType? recurrenceType,
    List<int>? recurrenceDays,
    int? reminderOffsetMinutes,
    String? goalId,
  }) {
    if (repo == null) return;
    final template = Task(
      id: repo.newId,
      title: title,
      level: level,
      order: order,
      date: date,
      notes: notes,
      isRecurring: isRecurring,
      recurrenceType: recurrenceType,
      recurrenceDays: recurrenceDays,
      reminderOffsetMinutes: reminderOffsetMinutes,
      goalId: goalId,
    );
    if (isRecurring && recurrenceType != null) {
      final dates = _datesForRecurrence(date, recurrenceType, recurrenceDays);
      repo.addRecurring(template, dates);
    } else {
      repo.add(template);
    }
  }
}

/// Returns every DateTime within 90 days of [start] (inclusive) that matches
/// the given [type] / [specificDays] pattern.
List<DateTime> _datesForRecurrence(
  DateTime start,
  RecurrenceType type,
  List<int>? specificDays, {
  int windowDays = 90,
}) {
  final dates = <DateTime>[];
  for (var i = 0; i <= windowDays; i++) {
    final d = DateTime(
      start.year,
      start.month,
      start.day,
    ).add(Duration(days: i));
    final include = switch (type) {
      RecurrenceType.daily => true,
      RecurrenceType.weekly => d.weekday == start.weekday,
      RecurrenceType.fortnightly => i % 14 == 0,
      RecurrenceType.monthly => d.day == start.day,
      RecurrenceType.specificDays => specificDays?.contains(d.weekday) ?? false,
    };
    if (include) dates.add(d);
  }
  return dates;
}

class _Header extends StatelessWidget {
  const _Header({required this.day, required this.dayBlocks});

  final DateTime day;
  final List<TimeBlock> dayBlocks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalMin = dayBlocks.fold<int>(0, (s, b) => s + b.duration.inMinutes);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timebox', style: AppTextStyles.heading2xl()),
              const SizedBox(height: 2),
              Text(
                totalMin == 0
                    ? 'Nothing scheduled yet'
                    : '${_fmtDuration(totalMin)} boxed in',
                style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.selected});

  final DateTime selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // Anchor to Monday of the week containing selected day.
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    final isCurrentWeek = _sameDay(
      now.subtract(Duration(days: now.weekday - 1)),
      monday,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => ref
                    .read(timeboxingDayProvider.notifier)
                    .set(selected.subtract(const Duration(days: 7))),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    isCurrentWeek
                        ? 'This week'
                        : '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d').format(monday.add(const Duration(days: 6)))}',
                    style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => ref
                    .read(timeboxingDayProvider.notifier)
                    .set(selected.add(const Duration(days: 7))),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(7, (i) {
                final day = monday.add(Duration(days: i));
                final isSel = _sameDay(day, selected);
                final isToday = _sameDay(day, now);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref
                        .read(timeboxingDayProvider.notifier)
                        .set(DateTime(day.year, day.month, day.day)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? scheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: isToday && !isSel
                            ? Border.all(
                                color: scheme.onSurface.withValues(alpha: 0.4),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat.E().format(day).substring(0, 1),
                            style: AppTextStyles.textXs(
                              color: isSel
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.day}',
                            style: AppTextStyles.labelMd(
                              color: isSel
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({required this.dayBlocks});

  final List<TimeBlock> dayBlocks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Text(
            'Schedule',
            style: AppTextStyles.headingXs(color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange40.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.orange40,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: AppTextStyles.labelSm(color: AppColors.orange40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _allTasksScheduled(List<Task> tasks, List<TimeBlock> blocks) {
  if (tasks.isEmpty) return true;
  return tasks.every((t) => isTaskScheduled(t, blocks));
}

String _fmtDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
