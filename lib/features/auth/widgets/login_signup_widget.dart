import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tb_button.dart';
import '../providers/auth_providers.dart';
import '../services/social_auth_service.dart';

class LoginSignupWidget extends ConsumerStatefulWidget {
  const LoginSignupWidget({super.key});

  @override
  ConsumerState<LoginSignupWidget> createState() => _LoginSignupWidgetState();
}

class _LoginSignupWidgetState extends ConsumerState<LoginSignupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _googleLoading = false;
  bool _appleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final isLogin = ref.read(isLoginModeProvider);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await cred.user?.sendEmailVerification();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'email': cred.user!.email,
              'createdAt': FieldValue.serverTimestamp(),
              'settings': {
                'maxPriorities': 3,
                'maxChores': 5,
                'dayStartHour': 6,
                'dayEndHour': 22,
                'snapMinutes': 30,
              },
            });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await SocialAuthService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Google sign-in failed.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in failed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _appleLoading = true);
    try {
      await SocialAuthService.signInWithApple();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Apple sign-in failed.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple sign-in failed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = ref.watch(isLoginModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final anyLoading = _isLoading || _googleLoading || _appleLoading;
    final showApple =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLogin ? 'Welcome back 👋' : 'Create account',
            style: AppTextStyles.heading2xl(),
          ),
          const SizedBox(height: 8),
          Text(
            isLogin
                ? 'Sign in to continue timeboxing.'
                : 'Start owning your time today.',
            style: AppTextStyles.textLg(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email.';
              if (!v.contains('@')) return 'Enter a valid email.';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password.';
              if (v.length < 8)
                return 'Password must be at least 8 characters.';
              if (v.length > 128) return 'Password too long.';
              return null;
            },
          ),

          if (!isLogin) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text)
                  return 'Passwords do not match.';
                return null;
              },
            ),
          ],

          const SizedBox(height: 24),
          TbButton(
            label: isLogin ? 'Sign in' : 'Create account',
            onPressed: anyLoading ? null : _submit,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),

          if (isLogin) ...[
            TbButton(
              label: 'Forgot password?',
              variant: TbButtonVariant.ghost,
              color: AppColors.orange40,
              onPressed: anyLoading
                  ? null
                  : () =>
                        ref.read(isForgotPasswordModeProvider.notifier).state =
                            true,
            ),
            const SizedBox(height: 8),
          ],

          TbButton(
            label: isLogin
                ? 'New here? Create account'
                : 'Already have an account? Sign in',
            variant: TbButtonVariant.ghost,
            color: AppColors.brown60,
            onPressed: anyLoading
                ? null
                : () => ref.read(isLoginModeProvider.notifier).state = !isLogin,
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: Divider(color: scheme.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                ),
              ),
              Expanded(child: Divider(color: scheme.outlineVariant)),
            ],
          ),
          const SizedBox(height: 16),

          _SocialButton(
            label: 'Continue with Google',
            icon: const _GoogleIcon(),
            onPressed: anyLoading ? null : _signInWithGoogle,
            isLoading: _googleLoading,
          ),

          if (showApple) ...[
            const SizedBox(height: 12),
            _SocialButton(
              label: 'Continue with Apple',
              icon: const _AppleIcon(),
              onPressed: anyLoading ? null : _signInWithApple,
              isLoading: _appleLoading,
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outline),
          shape: const StadiumBorder(),
          foregroundColor: scheme.onSurface,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onSurface,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: AppTextStyles.labelLg(color: scheme.onSurface),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF4285F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _AppleLogoPainter(color: color)),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  const _AppleLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(s.width * 0.50, s.height * 0.26)
      ..quadraticBezierTo(
        s.width * 0.82,
        s.height * 0.24,
        s.width * 0.90,
        s.height * 0.50,
      )
      ..quadraticBezierTo(
        s.width * 0.97,
        s.height * 0.74,
        s.width * 0.80,
        s.height * 0.90,
      )
      ..quadraticBezierTo(
        s.width * 0.65,
        s.height * 1.00,
        s.width * 0.50,
        s.height * 0.92,
      )
      ..quadraticBezierTo(
        s.width * 0.35,
        s.height * 1.00,
        s.width * 0.20,
        s.height * 0.90,
      )
      ..quadraticBezierTo(
        s.width * 0.03,
        s.height * 0.74,
        s.width * 0.10,
        s.height * 0.50,
      )
      ..quadraticBezierTo(
        s.width * 0.18,
        s.height * 0.24,
        s.width * 0.50,
        s.height * 0.26,
      )
      ..close();
    canvas.drawPath(body, fill);

    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.11
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(s.width * 0.50, s.height * 0.26)
      ..quadraticBezierTo(
        s.width * 0.52,
        s.height * 0.06,
        s.width * 0.70,
        s.height * 0.02,
      );
    canvas.drawPath(stem, stemPaint);

    final leaf = Path()
      ..moveTo(s.width * 0.54, s.height * 0.16)
      ..quadraticBezierTo(
        s.width * 0.76,
        s.height * 0.06,
        s.width * 0.78,
        s.height * 0.20,
      )
      ..quadraticBezierTo(
        s.width * 0.66,
        s.height * 0.18,
        s.width * 0.54,
        s.height * 0.16,
      )
      ..close();
    canvas.drawPath(leaf, fill);
  }

  @override
  bool shouldRepaint(_AppleLogoPainter old) => old.color != color;
}
