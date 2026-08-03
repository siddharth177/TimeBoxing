import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/app_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../main.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/time_block.dart';
import '../providers/timeline_provider.dart';
import '../widgets/add_block_sheet.dart';
import '../widgets/current_task_card.dart';
import '../widgets/time_slot_tile.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  late DateTime _selectedDay;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_now.year, _now.month, _now.day);
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.position.maxScrollExtent * 0.35).clamp(
        0,
        double.maxFinite,
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(timeBlocksProvider).value ?? [];
    final settings = ref.watch(appSettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final dayFmt = DateFormat('EEEE, MMM d');
    final timeFmt = DateFormat('h:mm a');

    final sorted = [...blocks]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final dayBlocks = sorted
        .where((b) => _sameDay(b.startTime, _selectedDay))
        .toList();
    final isToday = _sameDay(_selectedDay, _now);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            return isWide
                ? _wideLayout(
                    dayBlocks,
                    scheme,
                    dayFmt,
                    timeFmt,
                    settings,
                    isToday: isToday,
                  )
                : _narrowLayout(
                    dayBlocks,
                    scheme,
                    dayFmt,
                    timeFmt,
                    settings,
                    isToday: isToday,
                  );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-timeline',
        onPressed: () => AddBlockSheet.show(context, initialDate: _selectedDay),
        backgroundColor: AppColors.green60,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }

  Widget _narrowLayout(
    List<TimeBlock> sorted,
    ColorScheme scheme,
    DateFormat dayFmt,
    DateFormat timeFmt,
    AppSettings settings, {
    required bool isToday,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _header(scheme, dayFmt, timeFmt)),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 8),
              if (isToday) const CurrentTaskCard(),
              if (isToday) const SizedBox(height: 20),
              _sectionLabel('Timeline', scheme, isToday: isToday),
            ],
          ),
        ),
        _timelineSliver(sorted, scheme),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _wideLayout(
    List<TimeBlock> sorted,
    ColorScheme scheme,
    DateFormat dayFmt,
    DateFormat timeFmt,
    AppSettings settings, {
    required bool isToday,
  }) {
    return Row(
      children: [
        // Left — timeline
        Expanded(
          flex: 3,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _header(scheme, dayFmt, timeFmt)),
              SliverToBoxAdapter(
                child: _sectionLabel('Timeline', scheme, isToday: isToday),
              ),
              _timelineSliver(sorted, scheme),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: scheme.outlineVariant),
        // Right — current task + day summary
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _header(scheme, dayFmt, timeFmt, compact: true),
              if (isToday) const CurrentTaskCard(),
              if (isToday) const SizedBox(height: 20),
              _DaySummaryPanel(blocks: sorted),
            ],
          ),
        ),
      ],
    );
  }

  void _changeDay(DateTime day) {
    setState(() => _selectedDay = DateTime(day.year, day.month, day.day));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: _now.add(const Duration(days: 365)),
    );
    if (picked != null) _changeDay(picked);
  }

  Widget _header(
    ColorScheme scheme,
    DateFormat dayFmt,
    DateFormat timeFmt, {
    bool compact = false,
  }) {
    final isToday = _sameDay(_selectedDay, _now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          // Prev day
          GestureDetector(
            onTap: () =>
                _changeDay(_selectedDay.subtract(const Duration(days: 1))),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Date label — tap to open picker
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDay(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Today' : dayFmt.format(_selectedDay),
                    style: AppTextStyles.headingLg(),
                  ),
                  if (isToday)
                    Text(
                      timeFmt.format(_now),
                      style: AppTextStyles.displaySm(color: scheme.onSurface),
                    )
                  else
                    Text(
                      DateFormat('EEEE').format(_selectedDay),
                      style: AppTextStyles.textMd(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Next day
          GestureDetector(
            onTap: () => _changeDay(_selectedDay.add(const Duration(days: 1))),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'Introspect',
            onPressed: () => _showReview(context),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => ref.read(shellTabProvider.notifier).set(3),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (firebaseReady) FirebaseAuth.instance.signOut();
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.brown60,
              child: Text(
                firebaseReady
                    ? (FirebaseAuth.instance.currentUser?.email ?? 'U')
                          .substring(0, 1)
                          .toUpperCase()
                    : 'T',
                style: AppTextStyles.headingXs(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(
    String label,
    ColorScheme scheme, {
    required bool isToday,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Row(
      children: [
        Text(
          label,
          style: AppTextStyles.headingXs(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange40.withValues(alpha: 0.15),
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
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              DateFormat('MMM d').format(_selectedDay),
              style: AppTextStyles.labelSm(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    ),
  );

  SliverList _timelineSliver(List<TimeBlock> sorted, ColorScheme scheme) {
    return SliverList.builder(
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final block = sorted[i];
        return TimeSlotTile(
          block: block,
          isCurrentHour: block.isNow,
          onTap: () {},
          onToggle: () => ref
              .read(timeBlocksRepoProvider)
              ?.toggleComplete(block.id, block.isCompleted),
          onLongPress: () => _showReschedule(context, block),
        );
      },
    );
  }

  void _showReview(BuildContext context) {
    ReviewSheet.show(
      context,
      date: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day),
    );
  }

  void _showReschedule(BuildContext context, TimeBlock block) {
    _RescheduleSheet.show(
      context,
      block: block,
      repo: ref.read(timeBlocksRepoProvider),
    );
  }
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.block, required this.repo});

  final TimeBlock block;
  final TimeBlocksRepository? repo;

  static Future<void> show(
    BuildContext context, {
    required TimeBlock block,
    required TimeBlocksRepository? repo,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RescheduleSheet(block: block, repo: repo),
  );

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start = TimeOfDay.fromDateTime(widget.block.startTime);
    _end = TimeOfDay.fromDateTime(widget.block.endTime);
  }

  DateTime _combine(TimeOfDay t) {
    final base = widget.block.startTime;
    return DateTime(base.year, base.month, base.day, t.hour, t.minute);
  }

  Future<void> _pick({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        final s = _combine(_start);
        final e = _combine(_end);
        if (!e.isAfter(s)) {
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

  Future<void> _save() async {
    final startDt = _combine(_start);
    final endDt = _combine(_end);
    if (!endDt.isAfter(startDt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repo?.update(
        widget.block.copyWith(startTime: startDt, endTime: endDt),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = MaterialLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
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
          Text('Reschedule block', style: AppTextStyles.headingMd()),
          const SizedBox(height: 4),
          Text(
            widget.block.title,
            style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text(
            'New time',
            style: AppTextStyles.labelMd(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TimePill(
                label: fmt.formatTimeOfDay(
                  _start,
                  alwaysUse24HourFormat: false,
                ),
                onTap: () => _pick(isStart: true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '→',
                  style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
                ),
              ),
              _TimePill(
                label: fmt.formatTimeOfDay(_end, alwaysUse24HourFormat: false),
                onTap: () => _pick(isStart: false),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                    'Save',
                    style: AppTextStyles.labelLg(color: AppColors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: AppTextStyles.textMd()),
      ),
    );
  }
}

class _DaySummaryPanel extends StatelessWidget {
  const _DaySummaryPanel({required this.blocks});

  final List<TimeBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = blocks.where((b) => b.isCompleted).length;
    final total = blocks.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s progress', style: AppTextStyles.headingXs()),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$completed / $total tasks',
                style: AppTextStyles.headingMd(color: AppColors.green60),
              ),
              const Spacer(),
              Text(
                '${total == 0 ? 0 : (completed / total * 100).round()}%',
                style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              backgroundColor: AppColors.green10,
              valueColor: const AlwaysStoppedAnimation(AppColors.green60),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
