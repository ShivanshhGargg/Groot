import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../core/models/kairos_models.dart';

class MemoryDetailScreen extends ConsumerWidget {
  const MemoryDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(kairosRepositoryProvider);
    final memory = data.memoryById(id);

    if (memory == null) {
      return PageScaffold(
        title: 'Memory not found',
        child: KairosCard(
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to memories'),
            onPressed: () => context.go('/memories'),
          ),
        ),
      );
    }

    return PageScaffold(
      title: memory.title,
      subtitle: '${memory.source} - ${memory.updatedLabel}',
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
          final wide = constraints.maxWidth >= 900;
          final details = _DetailsPanel(memoryId: memory.id);
          final timeline = _TimelinePanel(memoryId: memory.id);
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: KairosSpacing.lg),
                timeline,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: details),
              const SizedBox(width: KairosSpacing.lg),
              Expanded(flex: 4, child: timeline),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsPanel extends ConsumerWidget {
  const _DetailsPanel({required this.memoryId});

  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(kairosRepositoryProvider);
    final memory = data.memoryById(memoryId)!;
    final confidence = confidenceColor(memory.confidenceLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: KairosSpacing.sm,
                runSpacing: KairosSpacing.sm,
                children: [
                  StatusPill(label: memory.type.label, color: Theme.of(context).colorScheme.primary),
                  StatusPill(
                    label: '${(memory.confidence * 100).round()}%',
                    icon: Icons.verified_outlined,
                    color: confidence,
                  ),
                  StatusPill(label: memory.status, color: confidence),
                ],
              ),
              const SizedBox(height: KairosSpacing.lg),
              for (final entry in memory.metadata.entries) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: KairosSpacing.sm),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
                const Divider(height: KairosSpacing.lg),
              ],
              const SizedBox(height: KairosSpacing.sm),
              Wrap(
                spacing: KairosSpacing.sm,
                runSpacing: KairosSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Confirm'),
                    onPressed: () {
                      ref.read(kairosRepositoryProvider.notifier).confirmMemory(memory.id);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.route_rounded),
                    label: const Text('Workflow'),
                    onPressed: () => context.go('/workflow/${memory.workflowId}'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit memory is ready for API wiring.')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelinePanel extends ConsumerWidget {
  const _TimelinePanel({required this.memoryId});

  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memory = ref.watch(kairosRepositoryProvider).memoryById(memoryId)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Version Timeline'),
        const SizedBox(height: KairosSpacing.md),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimelineEntry(
                title: memory.confirmed ? 'Confirmed by user' : 'Created by AI',
                subtitle: memory.updatedLabel,
                complete: true,
              ),
              _TimelineEntry(
                title: 'Fields extracted',
                subtitle: memory.metadata.keys.join(', '),
                complete: true,
              ),
              _TimelineEntry(
                title: 'Workflow activated',
                subtitle: memory.workflowId,
                complete: true,
              ),
              const _TimelineEntry(
                title: 'Future correction',
                subtitle: 'No changes yet',
                complete: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.title,
    required this.subtitle,
    required this.complete,
  });

  final String title;
  final String subtitle;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? KairosColors.success : Theme.of(context).disabledColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: KairosSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
          const SizedBox(width: KairosSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: KairosSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
