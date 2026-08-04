import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeboxing/services/calendar_service.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/notification_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/time_block.dart';
import '../providers/timeline_provider.dart';

const _uuid = Uuid();

const _blockColors = [
  AppColors.brown60,
  AppColors.green60,
  AppColors.orange40,
  AppColors.purple60,
  AppColors.yellow40,
  AppColors.gray40,
];

class AddBlockSheet extends ConsumerStatefulWidget {
  const AddBlockSheet({super.key, this.initialDate});

  final DateTime? initialDate;

  static Future<void> show(BuildContext context, {DateTime? initialDate}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => AddBlockSheet(initialDate: initialDate),
      );

  @override
  ConsumerState<AddBlockSheet> createState() => _AddBlockSheetState();
}

class _AddBlockSheetState extends ConsumerState<AddBlockSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  TimeBlockType _type = TimeBlockType.task;
  Color _color = AppColors.brown60;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
    _start = TimeOfDay(hour: base.hour, minute: 0);
    _end = TimeOfDay(hour: (base.hour + 1).clamp(0, 23), minute: 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay t) =>
      DateTime(date.year, date.month, date.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          final startDt = _combine(_date, _start);
          final endDt = _combine(_date, _end);
          if (!endDt.isAfter(startDt)) {
            _end = TimeOfDay(
              hour: (picked.hour + 1).clamp(0, 23),
              minute: picked.minute,
            );
          }
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final startDt = _combine(_date, _start);
    final endDt = _combine(_date, _end);
    if (!endDt.isAfter(startDt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final allBlocks = ref.read(timeBlocksProvider).value ?? [];
    final hasOverlap = allBlocks.any(
      (b) =>
          b.startTime.year == startDt.year &&
          b.startTime.month == startDt.month &&
          b.startTime.day == startDt.day &&
          startDt.isBefore(b.endTime) &&
          endDt.isAfter(b.startTime),
    );
    if (hasOverlap) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time overlaps with an existing block'),
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final notes = _notesCtrl.text.trim();
      final block = TimeBlock(
        id: _uuid.v4(),
        title: title,
        startTime: startDt,
        endTime: endDt,
        type: _type,
        color: _color,
        notes: notes.isEmpty ? null : notes,
      );
      final repo = ref.read(timeBlocksRepoProvider);
      await repo?.add(block);
      final appSettings = ref.read(appSettingsProvider);
      if (appSettings.notificationsEnabled) {
        await NotificationService.scheduleBlockReminder(
          blockId: block.id,
          title: block.title,
          startTime: block.startTime,
          minutesBefore: 5,
        );
      }
      if (appSettings.calendarSyncEnabled) {
        final calResult = await CalendarService.instance.addBlock(block);
        if (calResult != null) {
          await repo?.update(block.copyWith(calendarId: calResult.calendarId));
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save block: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = MaterialLocalizations.of(context);
    final showDesc = ref.watch(appSettingsProvider).showDescriptions;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text('New time block', style: AppTextStyles.headingMd()),
          const SizedBox(height: 20),

          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What are you blocking time for?',
            ),
          ),
          if (showDesc) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
            ),
          ],
          const SizedBox(height: 16),

          // Type selector
          Text(
            'Type',
            style: AppTextStyles.labelMd(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TimeBlockType.values.map((t) {
              final selected = t == _type;
              return ChoiceChip(
                label: Text(_typeLabel(t)),
                selected: selected,
                onSelected: (_) => setState(() {
                  _type = t;
                  _color = _defaultColor(t);
                }),
                selectedColor: _color.withValues(alpha: 0.2),
                labelStyle: AppTextStyles.labelSm(
                  color: selected ? _color : scheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: selected ? _color : scheme.outlineVariant,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Date + times row
          Text(
            'Schedule',
            style: AppTextStyles.labelMd(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TimePill(
                icon: Icons.calendar_today_outlined,
                label: '${_date.day}/${_date.month}/${_date.year}',
                onTap: _pickDate,
              ),
              const SizedBox(width: 8),
              _TimePill(
                icon: Icons.schedule_outlined,
                label: fmt.formatTimeOfDay(
                  _start,
                  alwaysUse24HourFormat: false,
                ),
                onTap: () => _pickTime(isStart: true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '→',
                  style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
                ),
              ),
              _TimePill(
                icon: null,
                label: fmt.formatTimeOfDay(_end, alwaysUse24HourFormat: false),
                onTap: () => _pickTime(isStart: false),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Color picker
          Text(
            'Colour',
            style: AppTextStyles.labelMd(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: _blockColors.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 10),
                  width: selected ? 34 : 28,
                  height: selected ? 34 : 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: scheme.onSurface, width: 2.5)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Save
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: scheme.primary,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    'Add block',
                    style: AppTextStyles.labelLg(color: AppColors.white),
                  ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(TimeBlockType t) => switch (t) {
    TimeBlockType.task => 'Task',
    TimeBlockType.chore => 'Chore',
    TimeBlockType.recurring => 'Recurring',
    TimeBlockType.free => 'Free',
  };

  Color _defaultColor(TimeBlockType t) => switch (t) {
    TimeBlockType.task => AppColors.brown60,
    TimeBlockType.chore => AppColors.yellow40,
    TimeBlockType.recurring => AppColors.green60,
    TimeBlockType.free => AppColors.gray40,
  };
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppTextStyles.textSm()),
          ],
        ),
      ),
    );
  }
}
