import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/groot_models.dart';

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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(GrootRadius.md),
        border: Border.all(color: color.withOpacity(0.24)),
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
    ConfidenceLevel.high => GrootColors.success,
    ConfidenceLevel.medium => GrootColors.warning,
    ConfidenceLevel.low => GrootColors.critical,
  };
}

Color workflowColor(WorkflowState state) {
  return switch (state) {
    WorkflowState.detected => GrootColors.primary,
    WorkflowState.approaching => GrootColors.warning,
    WorkflowState.critical => GrootColors.critical,
    WorkflowState.overdue => GrootColors.critical,
    WorkflowState.resolved => GrootColors.success,
  };
}
