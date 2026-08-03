import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── ReviewIllustration: animated daily-review card with streak badge ─────────

class ReviewIllustration extends StatefulWidget {
  const ReviewIllustration({super.key});

  @override
  State<ReviewIllustration> createState() => _ReviewIllustrationState();
}

class _ReviewIllustrationState extends State<ReviewIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

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
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final cardT = Curves.easeOutBack.transform(
            (_ctrl.value / 0.35).clamp(0.0, 1.0),
          );
          return Opacity(
            opacity: cardT.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.65 + 0.35 * cardT,
              child: _ReviewCard(progress: _ctrl.value),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.progress});

  final double progress;

  static const _tasks = [
    ('Deep Work — Project Alpha', true),
    ('Morning Review', true),
    ('Team Standup', false),
  ];

  static const _moodEmojis = ['😩', '😕', '😐', '😊', '😄'];

  @override
  Widget build(BuildContext context) {
    final rateT = ((progress - 0.42) / 0.30).clamp(0.0, 1.0);
    final streakT = ((progress - 0.75) / 0.22).clamp(0.0, 1.0);
    final moodT = ((progress - 0.87) / 0.18).clamp(0.0, 1.0);

    return Container(
      width: 272,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brown80,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green60.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.green60.withValues(alpha: 0.14),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 14,
                color: AppColors.green60,
              ),
              const SizedBox(width: 6),
              Text(
                'Daily Review',
                style: AppTextStyles.labelSm(color: AppColors.green60),
              ),
              const Spacer(),
              Text(
                'Today',
                style: AppTextStyles.textXs(color: AppColors.brown40),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Task rows
          ..._tasks.indexed.map((entry) {
            final i = entry.$1;
            final (label, done) = entry.$2;
            final t = ((progress - i * 0.12) / 0.22).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(-12 * (1 - Curves.easeOut.transform(t)), 0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: done ? AppColors.green60 : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: done ? AppColors.green60 : AppColors.brown40,
                          ),
                        ),
                        child: done
                            ? const Icon(
                                Icons.check,
                                size: 10,
                                color: AppColors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: AppTextStyles.textSm(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          // Completion bar
          Opacity(
            opacity: Curves.easeOut.transform(rateT),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Completion',
                      style: AppTextStyles.textXs(color: AppColors.brown40),
                    ),
                    const Spacer(),
                    Text(
                      '${(67 * rateT).round()}%',
                      style: AppTextStyles.labelSm(color: AppColors.green60),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: 0.67 * rateT,
                    minHeight: 5,
                    backgroundColor: AppColors.brown70,
                    valueColor: const AlwaysStoppedAnimation(AppColors.green60),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Mood row
          Opacity(
            opacity: Curves.easeOut.transform(moodT),
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - Curves.easeOut.transform(moodT))),
              child: Row(
                children: [
                  Text(
                    'Mood',
                    style: AppTextStyles.textXs(color: AppColors.brown40),
                  ),
                  const Spacer(),
                  ...List.generate(_moodEmojis.length, (i) {
                    final selected = i == 3; // '😊' Good
                    return Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: selected
                            ? const EdgeInsets.all(3)
                            : EdgeInsets.zero,
                        decoration: selected
                            ? BoxDecoration(
                                color: AppColors.brown60.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.brown60.withValues(
                                    alpha: 0.40,
                                  ),
                                ),
                              )
                            : null,
                        child: Text(
                          _moodEmojis[i],
                          style: TextStyle(fontSize: selected ? 16 : 12),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Streak badge
          Opacity(
            opacity: Curves.easeOut.transform(streakT),
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - Curves.easeOut.transform(streakT))),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange40.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.orange40.withValues(alpha: 0.40),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      '12-day streak',
                      style: AppTextStyles.textXs(color: AppColors.orange40),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
