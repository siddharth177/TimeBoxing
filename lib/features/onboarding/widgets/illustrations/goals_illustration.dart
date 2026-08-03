import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── Goals illustration: 3-tier hierarchy ────────────────────────────────────

class GoalsIllustration extends StatefulWidget {
  const GoalsIllustration({super.key});

  @override
  State<GoalsIllustration> createState() => _GoalsIllustrationState();
}

class _GoalsIllustrationState extends State<GoalsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _tiers = [
    (
      'LONG TERM',
      'Get into a top MBA program',
      '5-yr plan',
      AppColors.purple60,
    ),
    ('MEDIUM TERM', 'Ace the GMAT exam', '3 months', AppColors.green60),
    ('SHORT TERM', 'Complete 2 mock tests', 'This week', AppColors.orange40),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
      child: SizedBox(
        width: 280,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _tiers.length; i++) ...[
                  _animatedTier(i),
                  if (i < _tiers.length - 1) _connector(i),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _animatedTier(int i) {
    final (badge, title, time, color) = _tiers[i];
    const staggerStep = 0.22;
    final staggerStart = i * staggerStep;
    final localProgress =
        ((_ctrl.value - staggerStart) / (1.0 - staggerStart).clamp(0.001, 1.0))
            .clamp(0.0, 1.0);
    final anim = Curves.easeOutCubic.transform(localProgress);
    final indentLeft = i * 16.0;

    return Opacity(
      opacity: localProgress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(24 * (1 - anim), 0),
        child: Padding(
          padding: EdgeInsets.only(left: indentLeft),
          child: _GoalTierCard(
            badge: badge,
            title: title,
            time: time,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _connector(int i) {
    final color = _tiers[i].$4;
    final staggerStart = (i + 0.5) * 0.22;
    final t =
        ((_ctrl.value - staggerStart) / (1.0 - staggerStart).clamp(0.001, 1.0))
            .clamp(0.0, 1.0);
    final indentLeft = i * 16.0 + 22.0;

    return Padding(
      padding: EdgeInsets.only(left: indentLeft),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: Curves.easeIn.transform(t),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 1.5,
                  height: 14,
                  color: color.withValues(alpha: 0.38),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 11,
                  color: color.withValues(alpha: 0.50),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalTierCard extends StatelessWidget {
  const _GoalTierCard({
    required this.badge,
    required this.title,
    required this.time,
    required this.color,
  });

  final String badge, title, time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(badge, style: AppTextStyles.textXs(color: color)),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.labelSm(color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: AppTextStyles.textXs(color: color.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}
