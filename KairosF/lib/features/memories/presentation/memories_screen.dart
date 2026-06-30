import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/kairos_models.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/status_pill.dart';

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  String _query = '';
  MemoryType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final memories = ref.watch(kairosRepositoryProvider).memories.where((memory) {
      final matchesQuery = _query.isEmpty ||
          memory.title.toLowerCase().contains(_query.toLowerCase()) ||
          memory.metadata.values.any(
            (value) => value.toLowerCase().contains(_query.toLowerCase()),
          );
      final matchesType = _selectedType == null || memory.type == _selectedType;
      return matchesQuery && matchesType;
    }).toList();

    return PageScaffold(
      title: 'Memories',
      subtitle: 'Search, confirm, and correct what Kairos remembers.',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
          onPressed: () => context.go('/inbox'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search memories',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: KairosSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: KairosSpacing.sm),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                ),
                for (final type in MemoryType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: KairosSpacing.sm),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: _selectedType == type,
                      onSelected: (_) => setState(() => _selectedType = type),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: KairosSpacing.lg),
          if (memories.isEmpty)
            const KairosCard(child: Text('No memories yet.'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 680
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: memories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: KairosSpacing.md,
                    mainAxisSpacing: KairosSpacing.md,
                    mainAxisExtent: columns == 1 ? 190 : 220,
                  ),
                  itemBuilder: (context, index) {
                    return _MemoryCard(memory: memories[index]);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory});

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final color = confidenceColor(memory.confidenceLevel);
    final theme = Theme.of(context);
    return KairosCard(
      onTap: () => context.go('/memory/${memory.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForType(memory.type), color: theme.colorScheme.primary),
              const SizedBox(width: KairosSpacing.sm),
              Expanded(
                child: Text(
                  memory.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.sm),
          Wrap(
            spacing: KairosSpacing.sm,
            runSpacing: KairosSpacing.xs,
            children: [
              StatusPill(label: memory.type.label, color: theme.colorScheme.primary),
              StatusPill(
                label: memory.confidenceLevel.label,
                color: color,
                icon: Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.md),
          Text(
            memory.status,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  memory.source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
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
