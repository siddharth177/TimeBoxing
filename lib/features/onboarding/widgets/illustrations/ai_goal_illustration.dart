import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── AiGoalIllustration: goal → AI sparkle → medium → short breakdown ─────────

class AiGoalIllustration extends StatefulWidget {
  const AiGoalIllustration({super.key});

  @override
  State<AiGoalIllustration> createState() => _AiGoalIllustrationState();
}

class _AiGoalIllustrationState extends State<AiGoalIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => _buildTree(_ctrl.value),
    );
  }

  Widget _buildTree(double t) {
    return Center(
      child: SizedBox(
        width: 288,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill(
              'Become a Data Scientist',
              AppColors.purple60,
              0.0,
              t,
              isRoot: true,
            ),
            _sparkleRow(t, 0.18),
            Row(
              children: [
                Expanded(
                  child: _pill('Master Python & ML', AppColors.blue60, 0.28, t),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _pill('Build a Portfolio', AppColors.green60, 0.38, t),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _pill(
                    'Complete fast.ai',
                    AppColors.blue60,
                    0.52,
                    t,
                    small: true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _pill(
                    'Kaggle contest',
                    AppColors.green60,
                    0.60,
                    t,
                    small: true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _pill(
                    'GitHub projects',
                    AppColors.orange40,
                    0.68,
                    t,
                    small: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(
    String label,
    Color color,
    double staggerStart,
    double t, {
    bool isRoot = false,
    bool small = false,
  }) {
    final localT = ((t - staggerStart) / (1.0 - staggerStart).clamp(0.001, 1.0))
        .clamp(0.0, 1.0);
    final anim = Curves.easeOutBack.transform(localT);

    return Opacity(
      opacity: localT.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.55 + 0.45 * anim,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: small ? 8 : 12,
            vertical: small ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(isRoot ? 14 : 10),
            border: Border.all(
              color: color.withValues(alpha: isRoot ? 0.60 : 0.35),
              width: isRoot ? 1.5 : 1,
            ),
            boxShadow: isRoot
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRoot) ...[
                const Text('✨', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: small
                      ? AppTextStyles.textXs(color: AppColors.white)
                      : AppTextStyles.labelSm(color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sparkleRow(double t, double staggerStart) {
    final localT = ((t - staggerStart) / 0.14).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Opacity(
        opacity: Curves.easeOut.transform(localT),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 1.5,
              color: AppColors.purple60.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.purple60,
            ),
            const SizedBox(width: 4),
            Text(
              'Planning with AI…',
              style: AppTextStyles.textXs(color: AppColors.purple60),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 1.5,
              color: AppColors.purple60.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
