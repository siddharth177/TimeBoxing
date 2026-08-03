import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── Page 2: Vertical timeline with sliding task bars ──────────────────────

class TimelineIllustration extends StatefulWidget {
  const TimelineIllustration({super.key});

  @override
  State<TimelineIllustration> createState() => _TimelineIllustrationState();
}

class _TimelineIllustrationState extends State<TimelineIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _items = [
    ('Morning Review', '30m', AppColors.green60, 0.28),
    ('Deep Work', '2h', AppColors.brown60, 1.0),
    ('Team Standup', '30m', AppColors.orange40, 0.28),
    ('Lunch Break', '1h', AppColors.yellow40, 0.55),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Vertical line + dots column
          SizedBox(
            width: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _items.map((item) {
                final color = item.$3;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(width: 1.5, height: 40, color: AppColors.brown70),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 14),
          // Bars
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _items.indexed.map((entry) {
                final i = entry.$1;
                final (label, dur, color, maxFraction) = entry.$2;
                final staggerStart = i * 0.15;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, child) {
                      final raw = (_ctrl.value - staggerStart).clamp(0.0, 1.0);
                      final t = Curves.easeOutCubic.transform(
                        raw / (1.0 - staggerStart).clamp(0.001, 1.0),
                      );
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (maxFraction * t).clamp(0.0, 1.0),
                          child: Container(
                            height: 38,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: color.withValues(alpha: 0.55),
                              ),
                            ),
                            child: OverflowBox(
                              maxWidth: double.infinity,
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: AppTextStyles.labelSm(
                                        color: AppColors.white,
                                      ),
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '· $dur',
                                      style: AppTextStyles.textXs(color: color),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
