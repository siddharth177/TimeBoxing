import 'dart:math' show min, max;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../timeline/models/time_block.dart';
import '../../timeline/providers/timeline_provider.dart';
import '../models/task.dart';

bool isTaskScheduled(Task task, List<TimeBlock> blocks) =>
    blocks.any((b) => b.taskId == task.id);

class TimeTile extends StatelessWidget {
  const TimeTile({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(time.format(context), style: AppTextStyles.headingXs()),
          ],
        ),
      ),
    );
  }
}

class ScheduleTimeline extends StatefulWidget {
  const ScheduleTimeline({
    super.key,
    required this.day,
    required this.dayBlocks,
    required this.priorities,
    required this.chores,
    required this.startHour,
    required this.endHour,
    required this.snapMinutes,
    required this.blocksRepo,
  });

  final DateTime day;
  final List<TimeBlock> dayBlocks;
  final List<Task> priorities;
  final List<Task> chores;
  final int startHour;
  final int endHour;
  final int snapMinutes;
  final TimeBlocksRepository? blocksRepo;

  static const _kRowH = 58.0;

  @override
  State<ScheduleTimeline> createState() => _ScheduleTimelineState();
}

class _ScheduleTimelineState extends State<ScheduleTimeline> {
  int? _dragStart;
  int? _dragEnd;

  List<int> get _hours {
    final count =
        (widget.endHour > widget.startHour ? widget.endHour : 24) -
        widget.startHour;
    return List.generate(count, (i) => widget.startHour + i);
  }

  int _hourFromDy(double dy) {
    final h = _hours;
    final idx = (dy / ScheduleTimeline._kRowH).floor().clamp(0, h.length - 1);
    return h[idx];
  }

  bool get _isDragging => _dragStart != null && _dragEnd != null;

  bool _inRange(int hour) {
    if (!_isDragging) return false;
    final lo = min(_dragStart!, _dragEnd!);
    final hi = max(_dragStart!, _dragEnd!);
    return hour >= lo && hour <= hi;
  }

  void _openSlotDialog(BuildContext context, int startHour, [int? endHour]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleSlotDialog(
        day: widget.day,
        initialHour: startHour,
        initialEndHour: endHour,
        snapMinutes: widget.snapMinutes,
        priorities: widget.priorities,
        chores: widget.chores,
        dayBlocks: widget.dayBlocks,
        blocksRepo: widget.blocksRepo,
      ),
    );
  }

  void _openBlockEditSheet(BuildContext context, TimeBlock block) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlockEditSheet(
        block: block,
        day: widget.day,
        snapMinutes: widget.snapMinutes,
        blocksRepo: widget.blocksRepo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hours = _hours;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (d) => setState(() {
          _dragStart = _hourFromDy(d.localPosition.dy);
          _dragEnd = _dragStart;
        }),
        onVerticalDragUpdate: (d) {
          final h = _hourFromDy(d.localPosition.dy);
          if (h != _dragEnd) setState(() => _dragEnd = h);
        },
        onVerticalDragEnd: (_) {
          if (_isDragging) {
            _openSlotDialog(
              context,
              min(_dragStart!, _dragEnd!),
              max(_dragStart!, _dragEnd!) + 1,
            );
          }
          setState(() {
            _dragStart = null;
            _dragEnd = null;
          });
        },
        onVerticalDragCancel: () => setState(() {
          _dragStart = null;
          _dragEnd = null;
        }),
        child: Column(
          children: hours.map((h) => _buildRow(scheme, h)).toList(),
        ),
      ),
    );
  }

  Widget _buildRow(ColorScheme scheme, int hour) {
    final blocksHere = widget.dayBlocks
        .where(
          (b) =>
              b.startTime.hour == hour ||
              (b.startTime.hour < hour && b.endTime.hour > hour),
        )
        .toList();
    final highlighted = _inRange(hour);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      height: ScheduleTimeline._kRowH,
      color: highlighted
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _fmtHour(hour),
                style: AppTextStyles.textXs(
                  color: highlighted
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: ScheduleTimeline._kRowH,
            color: highlighted
                ? scheme.primary.withValues(alpha: 0.45)
                : scheme.outline.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: blocksHere.isEmpty
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openSlotDialog(context, hour),
                      child: Text(
                        highlighted ? '' : 'Tap to schedule',
                        style: AppTextStyles.textXs(
                          color: scheme.outlineVariant,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: blocksHere.map((b) {
                        final c = b.color ?? _blockTypeColor(b.type);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openBlockEditSheet(context, b),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: c.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.title,
                                  style: AppTextStyles.textXs(color: c),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 10,
                                  color: c.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtHour(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display $suffix';
  }
}

class ScheduleSlotDialog extends StatefulWidget {
  const ScheduleSlotDialog({
    super.key,
    required this.day,
    required this.initialHour,
    this.initialEndHour,
    required this.snapMinutes,
    required this.priorities,
    required this.chores,
    required this.dayBlocks,
    required this.blocksRepo,
  });

  final DateTime day;
  final int initialHour;
  final int? initialEndHour;
  final int snapMinutes;
  final List<Task> priorities;
  final List<Task> chores;
  final List<TimeBlock> dayBlocks;
  final TimeBlocksRepository? blocksRepo;

  @override
  State<ScheduleSlotDialog> createState() => _ScheduleSlotDialogState();
}

class _ScheduleSlotDialogState extends State<ScheduleSlotDialog> {
  Task? _selectedTask;
  late TimeOfDay _start;
  late TimeOfDay _end;
  Color? _selectedColor;
  bool _saving = false;

  static const _swatches = [
    AppColors.brown60,
    AppColors.green60,
    AppColors.orange40,
    AppColors.purple60,
    AppColors.yellow40,
  ];

  @override
  void initState() {
    super.initState();
    _start = TimeOfDay(hour: widget.initialHour, minute: 0);
    if (widget.initialEndHour != null) {
      _end = TimeOfDay(hour: widget.initialEndHour! % 24, minute: 0);
    } else {
      final endMin = widget.initialHour * 60 + widget.snapMinutes;
      _end = TimeOfDay(hour: (endMin ~/ 60) % 24, minute: endMin % 60);
    }
  }

  TimeOfDay _snap(TimeOfDay t) {
    final total = t.hour * 60 + t.minute;
    final snapped = (total / widget.snapMinutes).round() * widget.snapMinutes;
    return TimeOfDay(hour: (snapped ~/ 60) % 24, minute: snapped % 60);
  }

  List<(String label, Task task)> get _options => [
    for (var i = 0; i < widget.priorities.length; i++)
      ('P${i + 1}', widget.priorities[i]),
    for (var i = 0; i < widget.chores.length; i++)
      ('C${i + 1}', widget.chores[i]),
  ];

  Future<void> _pickStart() async {
    final p = await showTimePicker(context: context, initialTime: _start);
    if (p != null) {
      final snapped = _snap(p);
      final endMin = snapped.hour * 60 + snapped.minute + widget.snapMinutes;
      setState(() {
        _start = snapped;
        _end = TimeOfDay(hour: (endMin ~/ 60) % 24, minute: endMin % 60);
      });
    }
  }

  Future<void> _pickEnd() async {
    final p = await showTimePicker(context: context, initialTime: _end);
    if (p != null) setState(() => _end = _snap(p));
  }

  Future<void> _save() async {
    final task = _selectedTask;
    final repo = widget.blocksRepo;
    if (task == null || repo == null) return;
    setState(() => _saving = true);
    try {
      final start = DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        _start.hour,
        _start.minute,
      );
      final end = DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        _end.hour,
        _end.minute,
      );
      if (!end.isAfter(start)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await repo.add(
        TimeBlock(
          id: repo.newId,
          title: task.title,
          startTime: start,
          endTime: end,
          type: task.level == TaskLevel.priority
              ? TimeBlockType.task
              : TimeBlockType.chore,
          taskId: task.id,
          color: _selectedColor,
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
    final options = _options;
    final allChoresDone =
        widget.chores.isEmpty ||
        widget.chores.every((c) => isTaskScheduled(c, widget.dayBlocks));

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
          Text('Schedule a task', style: AppTextStyles.headingSm()),
          const SizedBox(height: 16),

          Text(
            'Select task',
            style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (options.isEmpty)
            Text(
              'Add priorities or chores first to schedule.',
              style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((opt) {
                    final (label, task) = opt;
                    final isSel = _selectedTask?.id == task.id;
                    final isDisabled =
                        task.level == TaskLevel.priority && !allChoresDone;
                    return GestureDetector(
                      onTap: isDisabled
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Schedule all chores first to unlock priorities.',
                                ),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            )
                          : () => setState(() => _selectedTask = task),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? scheme.surfaceContainerHighest
                              : isSel
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),

                          border: Border.all(
                            color: isDisabled
                                ? scheme.outline.withValues(alpha: 0.2)
                                : isSel
                                ? scheme.primary
                                : scheme.outline.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: AppTextStyles.labelSm(
                                color: isDisabled
                                    ? scheme.onSurfaceVariant.withValues(
                                        alpha: 0.4,
                                      )
                                    : isSel
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              task.title,
                              style: AppTextStyles.textXs(
                                color: isDisabled
                                    ? scheme.onSurface.withValues(alpha: 0.4)
                                    : scheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TimeTile(
                  label: 'Start',
                  time: _start,
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimeTile(label: 'End', time: _end, onTap: _pickEnd),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Color',
            style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: _swatches.map((c) {
              final isSel = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(
                  () => _selectedColor = _selectedColor == c ? null : c,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSel
                        ? Border.all(color: scheme.onSurface, width: 2.5)
                        : null,
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          TbButton(
            label: 'Schedule',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class BlockEditSheet extends StatefulWidget {
  const BlockEditSheet({
    super.key,
    required this.block,
    required this.day,
    required this.snapMinutes,
    required this.blocksRepo,
  });

  final TimeBlock block;
  final DateTime day;
  final int snapMinutes;
  final TimeBlocksRepository? blocksRepo;

  @override
  State<BlockEditSheet> createState() => _BlockEditSheetState();
}

class _BlockEditSheetState extends State<BlockEditSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start = TimeOfDay.fromDateTime(widget.block.startTime);
    _end = TimeOfDay.fromDateTime(widget.block.endTime);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    final start = DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      _start.hour,
      _start.minute,
    );
    final end = DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      _end.hour,
      _end.minute,
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
    setState(() => _saving = true);
    try {
      await widget.blocksRepo?.update(
        widget.block.copyWith(startTime: start, endTime: end),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await widget.blocksRepo?.delete(widget.block.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = widget.block.color ?? _blockTypeColor(widget.block.type);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.block.title,
                  style: AppTextStyles.headingSm(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.withValues(alpha: 0.4)),
                ),
                child: Text(
                  widget.block.type.name,
                  style: AppTextStyles.textXs(color: c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TimeTile(
                  label: 'Start',
                  time: _start,
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimeTile(
                  label: 'End',
                  time: _end,
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.5),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _saving ? null : _delete,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TbButton(
                  label: 'Save',
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _blockTypeColor(TimeBlockType type) => switch (type) {
  TimeBlockType.task => AppColors.brown60,
  TimeBlockType.chore => AppColors.orange40,
  TimeBlockType.recurring => AppColors.purple60,
  TimeBlockType.free => AppColors.green60,
};
