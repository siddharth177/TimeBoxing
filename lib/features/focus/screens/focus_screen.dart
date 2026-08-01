import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../timeline/models/time_block.dart';
import '../../timeline/providers/timeline_provider.dart';

const double _railWidth = 76.0;
const double _lineX = _railWidth - 5.0; // center of the 10-px dot

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  late final Timer _timer;
  DateTime _now = DateTime.now();
  late DateTime _selectedDay;
  final _dotKey = GlobalKey();
  final _stackKey = GlobalKey();
  double _dotFraction = 0.52;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureDot());
  }

  void _measureDot() {
    final dot = _dotKey.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (dot == null || stack == null || stack.size.height == 0) return;
    final offset = dot.localToGlobal(
      Offset(0, dot.size.height / 2),
      ancestor: stack,
    );
    final frac = (offset.dy / stack.size.height).clamp(0.05, 0.95);
    if ((frac - _dotFraction).abs() > 0.01) {
      setState(() => _dotFraction = frac);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isToday => _sameDay(_selectedDay, _now);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;

    final allBlocks = ref.watch(timeBlocksProvider).value ?? [];
    final dayBlocks =
        allBlocks.where((b) => _sameDay(b.startTime, _selectedDay)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    TimeBlock? block;
    TimeBlock? upNextBlock;
    Color accent;

    TimeBlock? nextAnyBlock;
    if (_isToday) {
      block =
          dayBlocks.where((b) => b.isNow).firstOrNull ??
          dayBlocks.where((b) => b.startTime.isAfter(_now)).firstOrNull;
      accent = block != null && block.isNow
          ? (block.color ?? AppColors.green60)
          : AppColors.green60;
      if (block != null && block.isNow) {
        upNextBlock = dayBlocks
            .where((b) => b.startTime.isAfter(_now))
            .firstOrNull;
      }
      if (block == null) {
        final future =
            allBlocks.where((b) => b.startTime.isAfter(_now)).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
        nextAnyBlock = future.firstOrNull;
      }
    } else {
      accent = scheme.onSurface.withValues(alpha: 0.10);
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        key: _stackKey,
        children: [
          Positioned(
            left: _lineX,
            top: 0,
            bottom: 0,
            width: 2,
            child: CustomPaint(
              painter: _DottedLinePainter(
                trackColor: scheme.onSurface.withValues(alpha: 0.18),
                accentColor: _isToday
                    ? accent
                    : scheme.onSurface.withValues(alpha: 0.18),
                dotFraction: _dotFraction,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateHeaderRow(day: _isToday ? _now : _selectedDay),
                if (isWide) ...[
                  const SizedBox(height: 8),
                  _DateStrip(
                    selected: _selectedDay,
                    onSelect: (day) => setState(() => _selectedDay = day),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  _DateNavRow(
                    selectedDay: _selectedDay,
                    isToday: _isToday,
                    onPrev: () => setState(
                      () => _selectedDay = _selectedDay.subtract(
                        const Duration(days: 1),
                      ),
                    ),
                    onToday: () => setState(() {
                      final n = DateTime.now();
                      _selectedDay = DateTime(n.year, n.month, n.day);
                    }),
                    onNext: () => setState(
                      () => _selectedDay = _selectedDay.add(
                        const Duration(days: 1),
                      ),
                    ),
                  ),
                ], // _DateNavRow
                Expanded(
                  child: _isToday
                      ? Center(
                          child: _NowRow(
                            now: _now,
                            block: block,
                            accentColor: accent,
                            dotKey: _dotKey,
                            nextBlock: nextAnyBlock,
                          ), // _NowRow
                        ) // Center
                      : _DayBlockList(
                          blocks: dayBlocks,
                          selectedDay: _selectedDay,
                        ), // _DayBlockList
                ), // Expanded
                if (_isToday && upNextBlock != null)
                  _UpNextBar(block: upNextBlock),
                const SizedBox(height: 12),
              ],
            ), // Column
          ), // SafeArea
        ],
      ), // Stack
    ); // Scaffold
  }
}

class _DateHeaderRow extends StatelessWidget {
  const _DateHeaderRow({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_railWidth + 12, 28, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(day),
                  style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                ), // Text
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMMM d').format(day),
                  style: AppTextStyles.headingLg(),
                ), // Text
              ],
            ), // Column
          ), // Expanded
        ],
      ), // Row
    ); // Padding
  }
}

class _NowRow extends StatelessWidget {
  const _NowRow({
    required this.now,
    required this.block,
    required this.accentColor,
    this.dotKey,
    this.nextBlock,
  });

  final DateTime now;
  final TimeBlock? block;
  final Color accentColor;
  final Key? dotKey;
  final TimeBlock? nextBlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('h:mm a').format(now);

    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _railWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    timeStr,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                  ), // Text
                ), // Flexible
                const SizedBox(width: 2),
                // Dot: right-aligned so center ≈ _lineX
                Container(
                  key: dotKey,
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ), // BoxShadow
                    ],
                  ), // BoxDecoration
                ), // Container
              ],
            ), // Row
          ), // SizedBox

          const SizedBox(width: 16),

          Expanded(
            child: block != null
                ? _TaskCard(block: block!)
                : _EmptyCard(nextBlock: nextBlock),
          ), // Expanded
        ],
      ), // Row
    ); // Padding
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.block});

  final TimeBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = block.color ?? AppColors.green60;
    final isNow = block.isNow;
    final startStr = DateFormat('h:mm a').format(block.startTime);
    final endStr = DateFormat('h:mm a').format(block.endTime);
    final remaining = block.endTime.difference(DateTime.now());
    final total = block.endTime.difference(block.startTime);
    final progress = (isNow && total.inSeconds > 0)
        ? (1 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0))
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNow
            ? accent.withValues(alpha: 0.10)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNow
              ? accent.withValues(alpha: 0.35)
              : scheme.outline.withValues(alpha: 0.4),
          width: 1.5,
        ), // Border.all
      ), // BoxDecoration
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isNow ? accent : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(6),
            ), // BoxDecoration
            child: Text(
              isNow ? 'NOW' : 'UP NEXT',
              style: AppTextStyles.textXs(
                color: isNow ? Colors.white : scheme.onSurfaceVariant,
              ),
            ), // Text
          ), // Container
          const SizedBox(height: 10),
          Text(block.title, style: AppTextStyles.headingSm()),
          const SizedBox(height: 4),
          Text(
            '$startStr → $endStr',
            style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
          ), // Text
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
                    ), // LinearProgressIndicator
                  ), // ClipRRect
                ), // Expanded
                const SizedBox(width: 12),
                Text(
                  _fmtRemaining(remaining),
                  style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                ), // Text
              ],
            ), // Row
          ],
        ],
      ), // Column
    ); // Container
  }
}

String _fmtRemaining(Duration d) {
  if (d.isNegative) return 'Done';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  if (d.inMinutes < 1) return '${d.inSeconds}s left';
  return '${d.inMinutes}m left';
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({this.nextBlock});

  final TimeBlock? nextBlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String subtitle;
    if (nextBlock != null) {
      final timeStr = DateFormat('h:mm a').format(nextBlock!.startTime);
      final isSameDay = nextBlock!.startTime.day == DateTime.now().day;
      subtitle = isSameDay
          ? 'Next: ${nextBlock!.title} at $timeStr'
          : 'Next: ${nextBlock!.title} – ${DateFormat('EEE h:mm a').format(nextBlock!.startTime)}';
    } else {
      subtitle = 'Nothing more scheduled today.';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ), // BoxDecoration
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Free time', style: AppTextStyles.headingSm()),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
          ), // Text
        ],
      ), // Column
    ); // Container
  }
}

class _UpNextBar extends StatelessWidget {
  const _UpNextBar({required this.block});

  final TimeBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final startStr = DateFormat('h:mm a').format(block.startTime);
    return Container(
      margin: const EdgeInsets.fromLTRB(_railWidth + 12, 0, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ), // BoxDecoration
      child: Row(
        children: [
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: scheme.onSurfaceVariant,
          ), // Icon
          const SizedBox(width: 6),
          Text(
            'Next $startStr',
            style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
          ), // Text
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              block.title,
              style: AppTextStyles.labelMd(color: scheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ), // Text
          ), // Expanded
        ],
      ), // Row
    ); // Container
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({
    required this.trackColor,
    required this.accentColor,
    this.dotFraction = 0.52,
  });

  final Color trackColor;
  final Color accentColor;
  final double dotFraction;

  static const _solidRadius = 52.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * dotFraction;
    final solidTop = cy - _solidRadius;
    final solidBot = cy + _solidRadius;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const dashH = 4.0;
    const dashGap = 6.0;

    // Top dotted section
    double y = 0;
    while (y < solidTop) {
      final end = (y + dashH).clamp(0.0, solidTop);
      if (end > y) canvas.drawLine(Offset(0, y), Offset(0, end), trackPaint);
      y += dashH + dashGap;
    }

    // Solid accent section ± solidRadius around the current-time dot
    canvas.drawLine(Offset(0, solidTop), Offset(0, solidBot), accentPaint);

    // Bottom dotted section
    y = solidBot;
    while (y < size.height) {
      final end = (y + dashH).clamp(0.0, size.height);
      if (end > y) canvas.drawLine(Offset(0, y), Offset(0, end), trackPaint);
      y += dashH + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) =>
      old.trackColor != trackColor ||
      old.accentColor != accentColor ||
      old.dotFraction != dotFraction;
}

class _DateNavRow extends StatelessWidget {
  const _DateNavRow({
    required this.selectedDay,
    required this.isToday,
    required this.onPrev,
    required this.onToday,
    required this.onNext,
  });

  final DateTime selectedDay;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _railWidth + 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            color: scheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
          ), // IconButton
          Expanded(
            child: GestureDetector(
              onTap: isToday ? null : onToday,
              child: Center(
                child: Text(
                  isToday
                      ? 'Today'
                      : DateFormat('EEE, MMM d').format(selectedDay),
                  style: AppTextStyles.labelMd(
                    color: isToday ? scheme.primary : scheme.onSurface,
                  ),
                ), // Text
              ), // Center
            ), // GestureDetector
          ), // Expanded
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: scheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
          ), // IconButton
        ],
      ), // Row
    ); // Padding
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selected, required this.onSelect});

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _railWidth + 12),
        child: Row(
          children: List.generate(7, (i) {
            final day = monday.add(Duration(days: i));
            final isSel = _sameDay(day, selected);
            final isToday = _sameDay(day, now);
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(DateTime(day.year, day.month, day.day)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSel ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSel
                        ? Border.all(
                            color: scheme.onSurface.withValues(alpha: 0.35),
                            width: 1.5,
                          ) // Border.all
                        : null,
                  ), // BoxDecoration
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
                      ), // Text
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: AppTextStyles.labelMd(
                          color: isSel ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ), // Text
                    ],
                  ), // Column
                ), // AnimatedContainer
              ), // GestureDetector
            ); // Expanded
          }), // List.generate
        ), // Row
      ), // Padding
    ); // SizedBox
  }
}

class _DayBlockList extends StatelessWidget {
  const _DayBlockList({required this.blocks, required this.selectedDay});

  final List<TimeBlock> blocks;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: scheme.outlineVariant,
            ), // Icon
            const SizedBox(height: 12),
            Text(
              'Nothing scheduled for ${DateFormat('EEEE').format(selectedDay)}',
              style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
            ), // Text
          ],
        ), // Column
      ); // Center
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(_railWidth + 12, 20, 24, 20),
      itemCount: blocks.length,
      itemBuilder: (_, i) {
        final b = blocks[i];
        final accent = b.color ?? AppColors.green60;
        final startStr = DateFormat('h:mm a').format(b.startTime);
        final endStr = DateFormat('h:mm a').format(b.endTime);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.4),
              ), // Border.all
            ), // BoxDecoration
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ), // BoxDecoration
                ), // Container
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        style:
                            AppTextStyles.labelMd(
                              color: b.isCompleted
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ).copyWith(
                              decoration: b.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ), // Text
                      const SizedBox(height: 2),
                      Text(
                        '$startStr → $endStr',
                        style: AppTextStyles.textSm(
                          color: scheme.onSurfaceVariant,
                        ),
                      ), // Text
                    ],
                  ), // Column
                ), // Expanded
                if (b.isCompleted)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.green60,
                  ), // Icon
              ],
            ), // Row
          ), // Container
        ); // Padding
      },
    ); // ListView.builder
  }
}
