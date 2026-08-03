import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── Page 4: Animated day ring ──────────────────────────────────────────────

class DayRingIllustration extends StatefulWidget {
  const DayRingIllustration({super.key});

  @override
  State<DayRingIllustration> createState() => _DayRingIllustrationState();
}

class _DayRingIllustrationState extends State<DayRingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, child) => CustomPaint(
              size: const Size(230, 230),
              painter: _DayRingPainter(_anim.value),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your',
                style: AppTextStyles.textMd(color: AppColors.brown40),
              ),
              Text(
                'Day',
                style: AppTextStyles.displaySm(color: AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayRingPainter extends CustomPainter {
  final double progress;

  const _DayRingPainter(this.progress);

  static const _blocks = [
    (8.0, 0.5, AppColors.green60),
    (9.0, 2.0, AppColors.brown60),
    (11.0, 0.5, AppColors.orange40),
    (13.0, 1.0, AppColors.yellow40),
    (14.0, 1.0, AppColors.purple60),
    (15.0, 1.0, AppColors.brown40),
    (18.0, 0.5, AppColors.green50),
  ];

  double _toStartAngle(double hour) =>
      (hour / 24.0) * 2 * math.pi - math.pi / 2;

  double _toDurationAngle(double hours) => (hours / 24.0) * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.brown70.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22,
    );

    // Colored arcs
    for (final (startHour, durationHours, color) in _blocks) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _toStartAngle(startHour),
        _toDurationAngle(durationHours) * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DayRingPainter old) => old.progress != progress;
}
