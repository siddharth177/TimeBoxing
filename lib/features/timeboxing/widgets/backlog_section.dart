import 'package:flutter/material.dart';
import 'package:timeboxing/features/timeboxing/widgets/schedule_section.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../goals/providers/goal_provider.dart';
import '../../timeline/models/time_block.dart';
import '../../timeline/providers/timeline_provider.dart';
import '../models/task.dart';

class BacklogSection extends StatelessWidget {
  const BacklogSection({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.slotColors,
    required this.tasks,
    required this.maxSlots,
    required this.dayBlocks,
    required this.isLocked,
    required this.showDescriptions,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onAssignTime,
    required this.onToggleComplete,
    this.linkableGoals = const [],
    this.lockMessage,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final List<Color> slotColors;
  final List<Task> tasks;
  final int maxSlots;
  final List<TimeBlock> dayBlocks;
  final bool isLocked;
  final bool showDescriptions;
  final List<Goal> linkableGoals;
  final String? lockMessage;
  final void Function(
    String title,
    String? notes,
    bool isRecurring,
    RecurrenceType? recurrenceType,
    List<int>? recurrenceDays,
    int? reminderOffsetMinutes,
    String? goalId,
  )
  onAddTask;
  final void Function(Task task) onEditTask;
  final void Function(Task task) onDeleteTask;
  final void Function(Task task) onAssignTime;
  final void Function(Task task) onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scheduled = tasks.where((t) => isTaskScheduled(t, dayBlocks)).length;
    final isPriority = label == 'Priorities';
    final slotLabel = isPriority ? 'P' : 'C';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 15),
              ),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.headingXs()),
              if (isLocked)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: scheme.outlineVariant,
                  ),
                ),
              const Spacer(),
              Text(
                '$scheduled / ${tasks.length}',
                style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isLocked && lockMessage != null && tasks.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                lockMessage!,
                style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
              ),
            ),
          ] else ...[
            for (var i = 0; i < maxSlots; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              if (i < tasks.length)
                Dismissible(
                  key: ValueKey(tasks[i].id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  onDismissed: (_) => onDeleteTask(tasks[i]),
                  child: _TaskRow(
                    task: tasks[i],
                    slotLabel: '$slotLabel${i + 1}',
                    slotColor: i < slotColors.length
                        ? slotColors[i]
                        : accentColor,
                    block: dayBlocks
                        .where((b) => b.taskId == tasks[i].id)
                        .firstOrNull,
                    isLocked: isLocked,
                    onAssignTime: () => isLocked
                        ? _showLockSnack(context)
                        : onAssignTime(tasks[i]),
                    onDelete: () => onDeleteTask(tasks[i]),
                    onToggle: () => onToggleComplete(tasks[i]),
                    onEdit: () => _showEditSheet(context, tasks[i]),
                  ),
                )
              else if (i == tasks.length && !(isLocked && lockMessage != null))
                _AddSlotButton(
                  hint: isPriority
                      ? 'Add ${_ordinal(tasks.length + 1)} priority'
                      : 'Add ${_ordinal(tasks.length + 1)} chore',
                  accentColor: accentColor,
                  onTap: () => _showAddSheet(context),
                ),
            ],
          ],
        ],
      ),
    );
  }

  void _showLockSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule all chores first before assigning priorities.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final showDesc = showDescriptions;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        var isRecurring = false;
        RecurrenceType? recType;
        var recDays = <int>{};
        var hasReminder = false;
        int? remOffset;
        final isPriority = label == 'Priorities';
        String? linkedGoalId;

        return StatefulBuilder(
          builder: (_, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label == 'Priorities'
                          ? 'New priority  (P${tasks.length + 1})'
                          : 'New chore  (C${tasks.length + 1})',
                      style: AppTextStyles.headingSm(),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: label == 'Priorities'
                            ? 'e.g. Deep Work'
                            : 'e.g. Morning workout',
                      ),
                    ),

                    if (showDesc) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Description (optional)',
                        ),
                      ),
                    ],

                    if (isPriority && linkableGoals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Links to goal',
                        style: AppTextStyles.textSm(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ChoiceChip(
                              label: 'None',
                              selected: linkedGoalId == null,
                              accentColor: accentColor,
                              onTap: () => setState(() => linkedGoalId = null),
                            ),
                            ...linkableGoals.map(
                              (g) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _ChoiceChip(
                                  label: g.priority != null
                                      ? 'P${g.priority}: ${g.title}'
                                      : g.title,
                                  selected: linkedGoalId == g.id,
                                  accentColor: accentColor,
                                  onTap: () =>
                                      setState(() => linkedGoalId = g.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),

                    _OptionToggleRow(
                      icon: Icons.repeat_rounded,
                      label: 'Recurring',
                      value: isRecurring,
                      accentColor: accentColor,
                      onChanged: (v) => setState(() {
                        isRecurring = v;
                        if (!v) {
                          recType = null;
                          recDays = {};
                        }
                      }),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: isRecurring
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: RecurrenceType.values
                                        .map(
                                          (t) => _ChoiceChip(
                                            label: _recurrenceLabel(t),
                                            selected: recType == t,
                                            accentColor: accentColor,
                                            onTap: () =>
                                                setState(() => recType = t),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  if (recType ==
                                      RecurrenceType.specificDays) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(7, (i) {
                                        final day = i + 1;
                                        final sel = recDays.contains(day);
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              if (sel) {
                                                recDays.remove(day);
                                              } else {
                                                recDays.add(day);
                                              }
                                            }),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: 36,
                                              height: 36,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: sel
                                                    ? accentColor
                                                    : accentColor.withValues(
                                                        alpha: 0.10,
                                                      ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                const [
                                                  'M',
                                                  'T',
                                                  'W',
                                                  'T',
                                                  'F',
                                                  'S',
                                                  'S',
                                                ][i],
                                                style: AppTextStyles.labelSm(
                                                  color: sel
                                                      ? Colors.white
                                                      : accentColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 8),

                    _OptionToggleRow(
                      icon: Icons.notifications_outlined,
                      label: 'Reminder',
                      value: hasReminder,
                      accentColor: AppColors.green60,
                      onChanged: (v) => setState(() {
                        hasReminder = v;
                        remOffset = v ? 0 : null;
                      }),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: hasReminder
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    const [
                                      (0, 'At start'),
                                      (5, '5 min before'),
                                      (10, '10 min before'),
                                      (15, '15 min before'),
                                    ].map((opt) {
                                      final (mins, lbl) = opt;
                                      return _ChoiceChip(
                                        label: lbl,
                                        selected: remOffset == mins,
                                        accentColor: AppColors.green60,
                                        onTap: () =>
                                            setState(() => remOffset = mins),
                                      );
                                    }).toList(),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),
                    TbButton(
                      label: 'Add',
                      onPressed: () {
                        final t = titleCtrl.text.trim();
                        if (t.isNotEmpty) {
                          final d = descCtrl.text.trim();
                          onAddTask(
                            t,
                            d.isEmpty ? null : d,
                            isRecurring,
                            isRecurring ? recType : null,
                            (isRecurring &&
                                    recType == RecurrenceType.specificDays &&
                                    recDays.isNotEmpty)
                                ? recDays.toList()
                                : null,
                            hasReminder ? remOffset : null,
                            isPriority ? linkedGoalId : null,
                          );
                          Navigator.of(ctx).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, Task task) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.notes ?? '');
    final isPriority = label == 'Priorities';

    var isRecurring = task.isRecurring;
    RecurrenceType? recType = task.recurrenceType;
    var recDays = task.recurrenceDays?.toSet() ?? <int>{};
    var hasReminder = task.reminderOffsetMinutes != null;
    int? remOffset = task.reminderOffsetMinutes;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPriority ? 'Edit priority' : 'Edit chore',
                      style: AppTextStyles.headingSm(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isPriority
                            ? 'e.g. Deep Work'
                            : 'e.g. Morning workout',
                      ),
                    ),
                    if (showDescriptions) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Description (optional)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),

                    _OptionToggleRow(
                      icon: Icons.repeat_rounded,
                      label: 'Recurring',
                      value: isRecurring,
                      accentColor: accentColor,
                      onChanged: (v) => setState(() {
                        isRecurring = v;
                        if (!v) {
                          recType = null;
                          recDays = {};
                        }
                      }),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: isRecurring
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: RecurrenceType.values
                                        .map(
                                          (t) => _ChoiceChip(
                                            label: _recurrenceLabel(t),
                                            selected: recType == t,
                                            accentColor: accentColor,
                                            onTap: () =>
                                                setState(() => recType = t),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  if (recType ==
                                      RecurrenceType.specificDays) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(7, (i) {
                                        final day = i + 1;
                                        final sel = recDays.contains(day);
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              if (sel) {
                                                recDays.remove(day);
                                              } else {
                                                recDays.add(day);
                                              }
                                            }),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: 36,
                                              height: 36,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: sel
                                                    ? accentColor
                                                    : accentColor.withValues(
                                                        alpha: 0.10,
                                                      ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                const [
                                                  'M',
                                                  'T',
                                                  'W',
                                                  'T',
                                                  'F',
                                                  'S',
                                                  'S',
                                                ][i],
                                                style: AppTextStyles.labelSm(
                                                  color: sel
                                                      ? Colors.white
                                                      : accentColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 8),

                    _OptionToggleRow(
                      icon: Icons.notifications_outlined,
                      label: 'Reminder',
                      value: hasReminder,
                      accentColor: AppColors.green60,
                      onChanged: (v) => setState(() {
                        hasReminder = v;
                        remOffset = v ? 0 : null;
                      }),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: hasReminder
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    const [
                                      (0, 'At start'),
                                      (5, '5 min before'),
                                      (10, '10 min before'),
                                      (15, '15 min before'),
                                    ].map((opt) {
                                      final (mins, lbl) = opt;
                                      return _ChoiceChip(
                                        label: lbl,
                                        selected: remOffset == mins,
                                        accentColor: AppColors.green60,
                                        onTap: () =>
                                            setState(() => remOffset = mins),
                                      );
                                    }).toList(),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),
                    TbButton(
                      label: 'Save',
                      onPressed: () {
                        final t = titleCtrl.text.trim();
                        if (t.isNotEmpty) {
                          final d = descCtrl.text.trim();
                          onEditTask(
                            Task(
                              id: task.id,
                              title: t,
                              level: task.level,
                              order: task.order,
                              date: task.date,
                              isCompleted: task.isCompleted,
                              notes: d.isEmpty ? null : d,
                              isRecurring: isRecurring,
                              recurrenceType: isRecurring ? recType : null,
                              recurrenceDays:
                                  (isRecurring &&
                                      recType == RecurrenceType.specificDays &&
                                      recDays.isNotEmpty)
                                  ? recDays.toList()
                                  : null,
                              reminderOffsetMinutes: hasReminder
                                  ? remOffset
                                  : null,
                              goalId: task.goalId,
                            ),
                          );
                          Navigator.of(ctx).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.slotLabel,
    required this.slotColor,
    required this.block,
    required this.isLocked,
    required this.onAssignTime,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
  });

  final Task task;
  final String slotLabel;
  final Color slotColor;
  final TimeBlock? block;
  final bool isLocked;
  final VoidCallback onAssignTime;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scheduled = block != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: slotColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(slotLabel, style: AppTextStyles.textXs(color: slotColor)),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  style:
                      AppTextStyles.textMd(
                        color: task.isCompleted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ).copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.notes!,
                    style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        if (scheduled)
          GestureDetector(
            onTap: onAssignTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.green60.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _fmtTime(block!.startTime),
                style: AppTextStyles.textXs(color: AppColors.green60),
              ),
            ),
          )
        else if (isLocked)
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: scheme.outlineVariant,
          )
        else
          GestureDetector(
            onTap: onAssignTime,
            child: Text(
              'Assign',
              style: AppTextStyles.labelSm(color: AppColors.orange40),
            ),
          ),

        const SizedBox(width: 12),

        GestureDetector(
          onTap: onDelete,
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: scheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}

class _AddSlotButton extends StatelessWidget {
  const _AddSlotButton({
    required this.hint,
    required this.accentColor,
    required this.onTap,
  });

  final String hint;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.add_circle_outline_rounded, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(
            hint,
            style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class AssignTimeSheet extends StatefulWidget {
  const AssignTimeSheet({
    super.key,
    required this.task,
    required this.date,
    required this.blocksRepo,
  });

  final Task task;
  final DateTime date;
  final TimeBlocksRepository? blocksRepo;

  static Future<void> show(
    BuildContext context, {
    required Task task,
    required DateTime date,
    required TimeBlocksRepository? blocksRepo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          AssignTimeSheet(task: task, date: date, blocksRepo: blocksRepo),
    );
  }

  @override
  State<AssignTimeSheet> createState() => _AssignTimeSheetState();
}

class _AssignTimeSheetState extends State<AssignTimeSheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(widget.date.year, widget.date.month, widget.date.day);
    if (date.isBefore(today)) {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    } else {
      final roundedMin = ((now.minute / 30).ceil() * 30) % 60;
      final addHour = ((now.minute / 30).ceil() * 30) >= 60 ? 1 : 0;
      _startTime = TimeOfDay(
        hour: (now.hour + addHour) % 24,
        minute: roundedMin,
      );
      _endTime = TimeOfDay(
        hour: (_startTime.hour + 1) % 24,
        minute: _startTime.minute,
      );
    }
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        final endMinutes = picked.hour * 60 + picked.minute + 60;
        _endTime = TimeOfDay(
          hour: (endMinutes ~/ 60) % 24,
          minute: endMinutes % 60,
        );
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    final repo = widget.blocksRepo;
    if (repo == null) return;
    setState(() => _saving = true);
    try {
      final start = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        _startTime.hour,
        _startTime.minute,
      );
      final end = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        _endTime.hour,
        _endTime.minute,
      );
      if (!end.isAfter(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await repo.add(
        TimeBlock(
          id: repo.newId,
          title: widget.task.title,
          startTime: start,
          endTime: end,
          type: widget.task.level == TaskLevel.priority
              ? TimeBlockType.task
              : TimeBlockType.chore,
          taskId: widget.task.id,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule task', style: AppTextStyles.headingSm()),
          const SizedBox(height: 4),
          Text(
            widget.task.title,
            style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TimeTile(
                  label: 'Start',
                  time: _startTime,
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimeTile(label: 'End', time: _endTime, onTap: _pickEnd),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TbButton(label: 'Schedule', onPressed: _save, isLoading: _saving),
        ],
      ),
    );
  }
}

class _OptionToggleRow extends StatelessWidget {
  const _OptionToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: value ? accentColor : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.textMd()),
        const Spacer(),
        Switch.adaptive(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.14)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? accentColor
                : scheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.textSm(
            color: selected ? accentColor : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _ordinal(int n) =>
    const [
      '',
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
      'ninth',
      'tenth',
    ].asMap()[n] ??
    '${n}th';

String _recurrenceLabel(RecurrenceType t) => switch (t) {
  RecurrenceType.daily => 'Every day',
  RecurrenceType.specificDays => 'Specific days',
  RecurrenceType.weekly => 'Every week',
  RecurrenceType.fortnightly => 'Fortnightly',
  RecurrenceType.monthly => 'Monthly',
};

String _fmtTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final suffix = dt.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $suffix';
}
