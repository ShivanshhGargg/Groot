import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/kairos_models.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/status_pill.dart';

class WorkflowDetailScreen extends ConsumerWidget {
  const WorkflowDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(kairosRepositoryProvider);
    final workflow = data.workflowById(id);

    if (workflow == null) {
      return PageScaffold(
        title: 'Workflow not found',
        child: KairosCard(
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to memories'),
            onPressed: () => context.go('/memories'),
          ),
        ),
      );
    }

    final stateColor = workflowColor(workflow.state);
    return PageScaffold(
      title: workflow.title,
      subtitle: workflow.typeLabel,
      actions: [
        Tooltip(
          message: 'Back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/memories'),
          ),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final status = _WorkflowStatus(id: id, stateColor: stateColor);
          final steps = _WorkflowSteps(id: id);

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: KairosSpacing.lg),
                steps,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: status),
              const SizedBox(width: KairosSpacing.lg),
              Expanded(flex: 6, child: steps),
            ],
          );
        },
      ),
    );
  }
}

class _WorkflowStatus extends ConsumerWidget {
  const _WorkflowStatus({
    required this.id,
    required this.stateColor,
  });

  final String id;
  final Color stateColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflow = ref.watch(kairosRepositoryProvider).workflowById(id)!;
    return KairosCard(
      borderColor: stateColor.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: workflow.state.label,
            icon: Icons.route_rounded,
            color: stateColor,
          ),
          const SizedBox(height: KairosSpacing.lg),
          Text('Snoozes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: KairosSpacing.sm),
          LinearProgressIndicator(
            value: workflow.snoozesUsed / 3,
            color: workflow.snoozesUsed >= 3 ? KairosColors.critical : stateColor,
            backgroundColor: stateColor.withValues(alpha: 0.12),
            minHeight: 8,
            borderRadius: BorderRadius.circular(KairosRadius.sm),
          ),
          const SizedBox(height: KairosSpacing.sm),
          Text('${workflow.snoozesUsed} of 3 used'),
          const SizedBox(height: KairosSpacing.lg),
          Wrap(
            spacing: KairosSpacing.sm,
            runSpacing: KairosSpacing.sm,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.done_rounded),
                label: const Text('Complete'),
                onPressed: () {
                  ref.read(kairosRepositoryProvider.notifier).resolveWorkflow(id);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.snooze_rounded),
                label: const Text('Snooze'),
                onPressed: workflow.snoozesUsed >= 3
                    ? null
                    : () {
                        ref.read(kairosRepositoryProvider.notifier).snoozeWorkflow(id);
                      },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Reassess'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Priority reassessment requested.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkflowSteps extends ConsumerWidget {
  const _WorkflowSteps({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflow = ref.watch(kairosRepositoryProvider).workflowById(id)!;
    return KairosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('State Machine', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: KairosSpacing.lg),
          for (var index = 0; index < workflow.steps.length; index++) ...[
            _StepRow(
              step: workflow.steps[index],
              showConnector: index < workflow.steps.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.showConnector,
  });

  final WorkflowStep step;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final color = step.complete ? KairosColors.success : Theme.of(context).disabledColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              step.complete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 44,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
        const SizedBox(width: KairosSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: KairosSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: KairosSpacing.xs),
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
