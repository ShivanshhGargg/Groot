import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/models/kairos_models.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(kairosRepositoryProvider);
    final profile = data.profile;
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return PageScaffold(
      title: 'Good morning, ${profile.fullName}',
      subtitle: today,
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
          onPressed: () => context.go('/inbox'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final main = _HomeMain(data: data);
          final side = _HomeSide(data: data);
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                main,
                const SizedBox(height: KairosSpacing.lg),
                side,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: main),
              const SizedBox(width: KairosSpacing.lg),
              Expanded(flex: 4, child: side),
            ],
          );
        },
      ),
    );
  }
}

class _HomeMain extends ConsumerWidget {
  const _HomeMain({required this.data});

  final KairosData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = data.dashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Your Next Move',
          subtitle: 'One decision at a time.',
        ),
        const SizedBox(height: KairosSpacing.md),
        if (dashboard.nextMove == null)
          const _AllClearCard()
        else
          _NextMoveCard(item: dashboard.nextMove!),
        const SizedBox(height: KairosSpacing.xl),
        SectionHeader(
          title: 'Everything Else',
          subtitle: '${dashboard.everythingElse.length} active commitments',
        ),
        const SizedBox(height: KairosSpacing.md),
        if (dashboard.everythingElse.isEmpty)
          const _AllClearCard()
        else
          Column(
            children: [
              for (final item in dashboard.everythingElse.take(5)) ...[
                _PriorityRow(item: item),
                const SizedBox(height: KairosSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _HomeSide extends StatelessWidget {
  const _HomeSide({required this.data});

  final KairosData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Risks'),
        const SizedBox(height: KairosSpacing.md),
        for (final risk in data.dashboard.risks) ...[
          _RiskCard(risk: risk),
          const SizedBox(height: KairosSpacing.sm),
        ],
        const SizedBox(height: KairosSpacing.lg),
        const SectionHeader(title: 'Daily Briefing'),
        const SizedBox(height: KairosSpacing.md),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final insight in data.dashboard.insights) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.insights_rounded, size: 18),
                    const SizedBox(width: KairosSpacing.sm),
                    Expanded(child: Text(insight)),
                  ],
                ),
                const SizedBox(height: KairosSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NextMoveCard extends ConsumerWidget {
  const _NextMoveCard({required this.item});

  final PriorityItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return KairosCard(
      borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(KairosRadius.md),
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: KairosSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: KairosSpacing.xs),
                    Text(
                      item.dueLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: '${item.estimatedMinutes} min',
                icon: Icons.schedule_rounded,
                color: KairosColors.primary,
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.lg),
          Text('Why this matters', style: theme.textTheme.titleMedium),
          const SizedBox(height: KairosSpacing.sm),
          for (final reason in item.reasons) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 18),
                const SizedBox(width: KairosSpacing.sm),
                Expanded(child: Text(reason)),
              ],
            ),
            const SizedBox(height: KairosSpacing.sm),
          ],
          const SizedBox(height: KairosSpacing.md),
          Wrap(
            spacing: KairosSpacing.sm,
            runSpacing: KairosSpacing.sm,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start now'),
                onPressed: () => context.go('/workflow/${item.workflowId}'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.done_rounded),
                label: const Text('Done'),
                onPressed: () {
                  ref.read(kairosRepositoryProvider.notifier).completeNextMove();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked complete.')),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.snooze_rounded),
                label: const Text('Snooze'),
                onPressed: () {
                  ref.read(kairosRepositoryProvider.notifier).snoozeNextMove();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.item});

  final PriorityItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KairosCard(
      onTap: () => context.go('/workflow/${item.workflowId}'),
      child: Row(
        children: [
          Icon(_iconForType(item.type), color: theme.colorScheme.primary),
          const SizedBox(width: KairosSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: KairosSpacing.xs),
                Text(
                  item.dueLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.risk});

  final RiskItem risk;

  @override
  Widget build(BuildContext context) {
    final color = confidenceColor(risk.severity);
    return KairosCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: risk.severity.label,
                icon: Icons.warning_amber_rounded,
                color: color,
              ),
              const Spacer(),
              Text(
                risk.dueLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.sm),
          Text(risk.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: KairosSpacing.xs),
          Text(risk.description),
        ],
      ),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  const _AllClearCard();

  @override
  Widget build(BuildContext context) {
    return KairosCard(
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: KairosColors.success),
          const SizedBox(width: KairosSpacing.md),
          Expanded(
            child: Text(
              'You are all caught up.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add something'),
            onPressed: () => context.go('/inbox'),
          ),
        ],
      ),
    );
  }
}

IconData _iconForType(MemoryType type) {
  return switch (type) {
    MemoryType.bill => Icons.receipt_long_rounded,
    MemoryType.exam => Icons.school_rounded,
    MemoryType.assignment => Icons.assignment_rounded,
    MemoryType.meeting => Icons.groups_rounded,
    MemoryType.subscription => Icons.autorenew_rounded,
    MemoryType.travel => Icons.flight_takeoff_rounded,
    MemoryType.goal => Icons.flag_rounded,
    MemoryType.note => Icons.notes_rounded,
  };
}
