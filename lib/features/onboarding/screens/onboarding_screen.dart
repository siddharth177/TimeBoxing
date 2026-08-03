import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../main.dart';
import '../../../services/notification_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/illustrations/ai_goal_illustration.dart';
import '../widgets/illustrations/backlog_illustration.dart';
import '../widgets/illustrations/day_ring_illustration.dart';
import '../widgets/illustrations/focus_card_illustration.dart';
import '../widgets/illustrations/goals_illustration.dart';

class _PageData {
  final String tag;
  final String title;
  final String subtitle;
  final Widget illustration;
  final Color accent;

  const _PageData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.accent,
  });
}

final _pages = const [
  _PageData(
    tag: 'THE CONCEPT',
    title: 'Assign every\nhour a purpose.',
    subtitle:
        'TimeBoxing means giving each task a fixed slot.\nWhen the box ends — you move on, no matter what.',
    illustration: TimeGridIllustration(),
    accent: AppColors.green60,
  ),
  _PageData(
    tag: 'THE VISION',
    title: 'Goals that\ndrive your day.',
    subtitle:
        'Long-term dreams break into medium milestones,\nthen into short-term tasks you can act on today.\n\n'
        'Every goal lives in one place — organised by horizon.',
    illustration: GoalsIllustration(),
    accent: AppColors.purple60,
  ),
  _PageData(
    tag: 'AI ASSISTANT',
    title: 'Let AI plan\nyour goals.',
    subtitle:
        'Add a goal and tap "Plan with AI". Gemini builds a full roadmap — medium milestones, short checkpoints, and daily tasks.\n\n'
        'Review, edit anything, then confirm with one tap.',
    illustration: AiGoalIllustration(),
    accent: AppColors.purple60,
  ),
  _PageData(
    tag: 'THE SYSTEM',
    title: 'Chores first,\nthen priorities.',
    subtitle:
        'Chores = daily non-negotiables (email, admin, routines).\n'
        'Priorities = the 2–3 tasks that move the needle.\n\n'
        'Miss a day? Unfinished tasks carry over automatically.',
    illustration: BacklogIllustration(),
    accent: AppColors.orange40,
  ),
  _PageData(
    tag: 'THE PLAN',
    title: 'Stack tasks like\nbuilding blocks.',
    subtitle:
        'Build your day in minutes — deep work, breaks, admin.\n'
        'Add recurring tasks once and they appear every day automatically.',
    illustration: TimelineIllustration(),
    accent: AppColors.brown60,
  ),
  _PageData(
    tag: 'THE FOCUS',
    title: 'Always know\nwhat\'s next.',
    subtitle:
        'Your current block and countdown are always visible.\n'
        'Get a notification before each block starts — no context-switching, no guessing.',
    illustration: FocusCardIllustration(),
    accent: AppColors.orange40,
  ),
  _PageData(
    tag: 'THE REVIEW',
    title: 'Reflect.\nBuild streaks.',
    subtitle:
        'End each day with a quick review — log what you completed and rate your mood.\n\n'
        'After 7 logs, AI surfaces personalised insights. A 9 pm nudge keeps your streak alive.',
    illustration: ReviewIllustration(),
    accent: AppColors.green60,
  ),
  _PageData(
    tag: 'LET\'S GO',
    title: 'Your best day\nstarts now.',
    subtitle:
        'Set your first goal, plan today\'s time-boxes, and let TimeBox keep you on track.\n\n'
        'Tap "Get Started" to enable reminders and begin.',
    illustration: DayRingIllustration(),
    accent: AppColors.purple60,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onboardingSeen && mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await NotificationService.requestPermissions();
    await markOnboardingSeen();
    // ignore: avoid_dynamic_calls
    onboardingSeen = true;
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final accent = _pages[_page].accent;

    return Scaffold(
      backgroundColor: AppColors.brown120,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.25),
                radius: 0.75,
                colors: [accent.withValues(alpha: 0.14), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_page < _pages.length - 1)
                          TextButton(
                            onPressed: _finish,
                            child: Text(
                              'Skip',
                              style: AppTextStyles.textMd(
                                color: AppColors.brown40,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
                  ),
                ),

                _Controls(
                  page: _page,
                  total: _pages.length,
                  accent: accent,
                  isLast: _page == _pages.length - 1,
                  onNext: _next,
                  onBack: _page > 0 ? _back : null,
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _PageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(
            flex: 55,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: data.illustration,
            ),
          ),
          Expanded(
            flex: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: data.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: data.accent.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Text(
                    data.tag,
                    style: AppTextStyles.labelSm(color: data.accent),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.title,
                  style: AppTextStyles.displaySm(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  style: AppTextStyles.textLg(color: AppColors.brown40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.page,
    required this.total,
    required this.accent,
    required this.isLast,
    required this.onNext,
    this.onBack,
  });

  final int page, total;
  final Color accent;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: onBack != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: onBack == null,
              child: ClipOval(
                child: Material(
                  color: AppColors.brown70.withValues(alpha: 0.55),
                  child: InkWell(
                    onTap: onBack,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(total, (i) {
              final active = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? accent : AppColors.brown70,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onNext,
                  splashColor: Colors.white.withValues(alpha: 0.20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLast ? 26 : 20,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLast ? 'Get Started' : 'Next',
                          style: AppTextStyles.labelMd(color: AppColors.white),
                        ),
                        if (!isLast) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
