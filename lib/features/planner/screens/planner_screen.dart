import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../timeline/models/time_block.dart';
import '../../timeline/providers/timeline_provider.dart';
import '../../timeline/widgets/add_block_sheet.dart';

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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Planner', style: AppTextStyles.heading2xl()),
                      Text(
                        '$completedCount / ${dayBlocks.length} done · ${_fmtDuration(totalMin)}',
                        style: AppTextStyles.textMd(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _DayStrip(selected: selectedDay),
            const SizedBox(height: 8),

            Expanded(
              child: dayBlocks.isEmpty
                  ? _EmptyDay(day: selectedDay)
                  : _Schedule(blocks: dayBlocks, ref: ref),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-planner',
        onPressed: () => AddBlockSheet.show(context, initialDate: selectedDay),
        backgroundColor: AppColors.green60,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}

class _DayStrip extends ConsumerWidget {
  const _DayStrip({required this.selected});

  final DateTime selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (_, i) {
          final day = monday.add(Duration(days: i));
          final isSel = _sameDay(day, selected);
          final isToday = _sameDay(day, now);
          return GestureDetector(
            onTap: () => ref
                .read(_selectedDayProvider.notifier)
                .set(DateTime(day.year, day.month, day.day)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSel
                    ? Border.all(color: scheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(day).substring(0, 1),
                    style: AppTextStyles.textXs(
                      color: isSel ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: AppTextStyles.labelMd(
                      color: isSel ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Schedule extends StatelessWidget {
  const _Schedule({required this.blocks, required this.ref});

  final List<TimeBlock> blocks;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  List<Widget> _buildItems() {
    final widgets = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      final prev = i == 0 ? null : blocks[i - 1];
      final gapStart = prev?.endTime ?? block.startTime;
      final gapMinutes = block.startTime.difference(gapStart).inMinutes;
      if (gapMinutes >= 15) {
        widgets.add(_FreeSlot(minutes: gapMinutes, time: gapStart));
      }

      widgets.add(
        _BlockTile(
          block: block,
          onToggle: () => ref
              .read(timeBlocksRepoProvider)
              ?.toggleComplete(block.id, block.isCompleted),
        ),
      );
    }
    return widgets;
  }
}

class _FreeSlot extends StatelessWidget {
  const _FreeSlot({required this.minutes, required this.time});

  final int minutes;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            _fmtTime(time),
            style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(child: DashedDivider(color: scheme.outlineVariant)),
          const SizedBox(width: 12),
          Text(
            'Free · ${_fmtDuration(minutes)}',
            style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.block, required this.onToggle});

  final TimeBlock block;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = block.color ?? _defaultColor(block.type);
    final dur = block.duration.inMinutes;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          block.title,
          style:
              AppTextStyles.textMd(
                color: block.isCompleted
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ).copyWith(
                decoration: block.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
        ),
        subtitle: Text(
          '${_fmtTime(block.startTime)} – ${_fmtTime(block.endTime)}  ·  ${_fmtDuration(dur)}',
          style: AppTextStyles.textXs(color: scheme.onSurfaceVariant),
        ),
        leading: _TypeIcon(type: block.type, color: color),
        trailing: GestureDetector(
          onTap: onToggle,
          child: Icon(
            block.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: block.isCompleted
                ? AppColors.green60
                : scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, required this.color});

  final TimeBlockType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      TimeBlockType.task => Icons.work_outline_rounded,
      TimeBlockType.chore => Icons.home_outlined,
      TimeBlockType.recurring => Icons.repeat_rounded,
      TimeBlockType.free => Icons.self_improvement_rounded,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 56,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No blocks for ${DateFormat('EEEE').format(day)}',
            style: AppTextStyles.headingXs(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first time block',
            style: AppTextStyles.textMd(color: scheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashPainter(color));
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashW = 4.0, gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashW, size.height / 2),
        paint,
      );
      x += dashW + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _fmtDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

Color _defaultColor(TimeBlockType type) => switch (type) {
  TimeBlockType.task => AppColors.brown60,
  TimeBlockType.chore => AppColors.orange40,
  TimeBlockType.recurring => AppColors.purple60,
  TimeBlockType.free => AppColors.green60,
};
