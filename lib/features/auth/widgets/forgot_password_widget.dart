import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tb_button.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordWidget extends ConsumerStatefulWidget {
  const ForgotPasswordWidget({super.key});

  @override
  ConsumerState<ForgotPasswordWidget> createState() =>
      _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends ConsumerState<ForgotPasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset email sent — check your inbox.')),
        );
        ref.read(isForgotPasswordModeProvider.notifier).state = false;
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Something went wrong.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reset password', style: AppTextStyles.heading2xl()),
          const SizedBox(height: 8),
          Text(
            'Enter your email and we\'ll send a reset link.',
            style: AppTextStyles.textLg(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
          const SizedBox(height: 24),
          TbButton(
            label: 'Send reset link',
            onPressed: _submit,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          TbButton(
            label: 'Back to sign in',
            variant: TbButtonVariant.ghost,
            color: AppColors.brown60,
            onPressed: () =>
                ref.read(isForgotPasswordModeProvider.notifier).state = false,
          ),
        ],
      ),
    );
  }
}
