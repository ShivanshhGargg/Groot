import 'package:flutter/material.dart';

import '../../app/theme.dart';

class KairosCard extends StatelessWidget {
  const KairosCard({
    required this.child,
    this.padding = const EdgeInsets.all(KairosSpacing.md),
    this.color,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(KairosRadius.md),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outline,
        ),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KairosRadius.md),
      child: content,
    );
  }
}
