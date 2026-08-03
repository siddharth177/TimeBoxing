import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── BacklogIllustration ──────────────────────────────────────────────────────

class BacklogIllustration extends StatefulWidget {
  const BacklogIllustration({super.key});

  @override
  State<BacklogIllustration> createState() => _BacklogIllustrationState();
}

class _BacklogIllustrationState extends State<BacklogIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _chores = ['Morning review', 'Team standup', 'Clear inbox'];
  static const _priorities = ['Deep work', 'Code review', 'Client call'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
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
        width: 270,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = _ctrl.value;
            final unlocked = t > 0.72;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chores card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brown80,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.orange40.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.orange40,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CHORES',
                            style: AppTextStyles.labelSm(
                              color: AppColors.orange40,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._chores.indexed.map((entry) {
                        final i = entry.$1;
                        final label = entry.$2;
                        final slideT = ((t - i * 0.10) / 0.28).clamp(0.0, 1.0);
                        final checkT = ((t - (0.38 + i * 0.09)) / 0.14).clamp(
                          0.0,
                          1.0,
                        );
                        final checked = checkT >= 1.0;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i < _chores.length - 1 ? 10 : 0,
                          ),
                          child: Opacity(
                            opacity: slideT,
                            child: Transform.translate(
                              offset: Offset(
                                -16 * (1 - Curves.easeOut.transform(slideT)),
                                0,
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: checked
                                          ? AppColors.orange40
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: checked
                                            ? AppColors.orange40
                                            : AppColors.brown40,
                                      ),
                                    ),
                                    child: checked
                                        ? const Icon(
                                            Icons.check,
                                            size: 11,
                                            color: AppColors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    label,
                                    style: AppTextStyles.textSm(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Lock divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.brown70.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? AppColors.green60.withValues(alpha: 0.15)
                              : AppColors.brown70.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          unlocked
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline,
                          size: 16,
                          color: unlocked
                              ? AppColors.green60
                              : AppColors.brown40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.brown70.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Priorities card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brown80,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: unlocked
                          ? AppColors.brown60.withValues(alpha: 0.55)
                          : AppColors.brown70.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: unlocked
                                  ? AppColors.brown60
                                  : AppColors.brown70,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 350),
                            style: AppTextStyles.labelSm(
                              color: unlocked
                                  ? AppColors.brown60
                                  : AppColors.brown70,
                            ),
                            child: const Text('PRIORITIES'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._priorities.indexed.map((entry) {
                        final i = entry.$1;
                        final label = entry.$2;
                        final fadeT = ((t - (0.80 + i * 0.06)) / 0.14).clamp(
                          0.0,
                          1.0,
                        );
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i < _priorities.length - 1 ? 10 : 0,
                          ),
                          child: Opacity(
                            opacity: unlocked ? fadeT.clamp(0.15, 1.0) : 0.15,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                8 * (1 - Curves.easeOut.transform(fadeT)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.brown60.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'P${i + 1}',
                                      style: AppTextStyles.textXs(
                                        color: AppColors.brown60,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    label,
                                    style: AppTextStyles.textSm(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
