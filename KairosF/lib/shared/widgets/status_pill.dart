import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/kairos_models.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KairosRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

Color confidenceColor(ConfidenceLevel level) {
  return switch (level) {
    ConfidenceLevel.high => KairosColors.success,
    ConfidenceLevel.medium => KairosColors.warning,
    ConfidenceLevel.low => KairosColors.critical,
  };
}

Color workflowColor(WorkflowState state) {
  return switch (state) {
    WorkflowState.detected => KairosColors.primary,
    WorkflowState.approaching => KairosColors.warning,
    WorkflowState.critical => KairosColors.critical,
    WorkflowState.overdue => KairosColors.critical,
    WorkflowState.resolved => KairosColors.success,
  };
}
