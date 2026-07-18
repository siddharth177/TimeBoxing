import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

enum TbButtonVariant { filled, outlined, ghost }

class TbButton extends StatelessWidget {
  const TbButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = TbButtonVariant.filled,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final TbButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.primary;

    return switch (variant) {
      TbButtonVariant.filled => FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.onPrimary,
          ),
        )
            : icon ?? const SizedBox.shrink(),
        label: Text(label, style: AppTextStyles.labelLg(color: scheme.onPrimary)),
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      TbButtonVariant.outlined => OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(label, style: AppTextStyles.labelLg(color: bg)),
        style: OutlinedButton.styleFrom(
          foregroundColor: bg,
          side: BorderSide(color: bg, width: 1.5),
          shape: const StadiumBorder(),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      TbButtonVariant.ghost => TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(label, style: AppTextStyles.labelLg(color: bg)),
      ),
    };
  }
}
