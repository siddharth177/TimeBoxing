import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── Page 3: Floating mock task card ────────────────────────────────────────

class FocusCardIllustration extends StatefulWidget {
  const FocusCardIllustration({super.key});

  @override
  State<FocusCardIllustration> createState() => _FocusCardIllustrationState();
}

class _FocusCardIllustrationState extends State<FocusCardIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _enter;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _enter = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack);
    _float = Tween<double>(
      begin: -9.0,
      end: 9.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _float]),
        builder: (_, child) => Opacity(
          opacity: _enter.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - _enter.value) * 50 + _float.value),
            child: child,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown60.withValues(alpha: 0.28),
                    blurRadius: 48,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
            const _MockCard(),
          ],
        ),
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brown80,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brown60.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                'NOW',
                style: AppTextStyles.labelSm(color: AppColors.orange40),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Deep Work — Project Alpha',
            style: AppTextStyles.headingXs(color: AppColors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '09:00 → 11:00',
            style: AppTextStyles.textSm(color: AppColors.brown40),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.60,
              minHeight: 4,
              backgroundColor: AppColors.brown70,
              valueColor: const AlwaysStoppedAnimation(AppColors.brown60),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '60% · 48 min remaining',
            style: AppTextStyles.textXs(color: AppColors.brown40),
          ),
        ],
      ),
    );
  }
}
