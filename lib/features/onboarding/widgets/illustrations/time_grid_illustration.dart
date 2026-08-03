import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── Page 1: 3×2 grid of time blocks ──────────────────────────────────────

class TimeGridIllustration extends StatefulWidget {
  const TimeGridIllustration({super.key});

  @override
  State<TimeGridIllustration> createState() => _TimeGridIllustrationState();
}

class _TimeGridIllustrationState extends State<TimeGridIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _blocks = [
    ('8:00', '30m', AppColors.green60, false),
    ('9:00', '2h', AppColors.brown60, true),
    ('11:00', '30m', AppColors.orange40, false),
    ('13:00', '1h', AppColors.yellow40, false),
    ('14:00', '1h', AppColors.purple60, false),
    ('15:00', '1h', AppColors.brown40, false),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _blocks.indexed.map((entry) {
          final i = entry.$1;
          final (time, dur, color, isActive) = entry.$2;
          final staggerStart = i * 0.10;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              final raw = (_ctrl.value - staggerStart).clamp(0.0, 1.0);
              final t = Curves.elasticOut.transform(
                raw / (1.0 - staggerStart).clamp(0.001, 1.0),
              );
              return Opacity(
                opacity: (t * 3).clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.3 + t * 0.7, child: child),
              );
            },
            child: _TimeBlock(
              time: time,
              dur: dur,
              color: color,
              active: isActive,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.time,
    required this.dur,
    required this.color,
    required this.active,
  });

  final String time, dur;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.85 : 0.30),
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (active) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('NOW', style: AppTextStyles.textXs(color: color)),
            ),
          ],
          Text(time, style: AppTextStyles.labelMd(color: AppColors.white)),
          const SizedBox(height: 3),
          Text(dur, style: AppTextStyles.textXs(color: color)),
        ],
      ),
    );
  }
}
