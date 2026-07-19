import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox/core/theme/app_colors.dart';
import 'package:timebox/features/auth/providers/auth_provider.dart';
import 'package:timebox/features/auth/widgets/forgot_password_widget.dart';
import 'package:timebox/features/auth/widgets/login_signup_widget.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isForgot = ref.watch(isForgotPasswordModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Circle(
              size: 260,
              color: AppColors.brown60.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _Circle(
              size: 320,
              color: AppColors.green60.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: _Circle(
              size: 140,
              color: AppColors.orange40.withValues(alpha: 0.08),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.timer_outlined,
                            color: scheme.onPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TimeBox',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: scheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isForgot
                          ? const ForgotPasswordWidget(key: ValueKey('forgot'))
                          : const LoginSignupWidget(key: ValueKey('login')),
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

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
