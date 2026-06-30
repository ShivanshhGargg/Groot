import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/kairos_models.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(kairosRepositoryProvider);

    return PageScaffold(
      title: 'Manager Inbox',
      subtitle: data.profile.kairosInboxAddress,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final capture = _CapturePanel(
            textController: _textController,
            inboxAddress: data.profile.kairosInboxAddress,
            onSubmit: _submitText,
            onPickFiles: _pickFiles,
          );
          final review = _ReviewQueue(items: data.needsReview);

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                capture,
                const SizedBox(height: KairosSpacing.lg),
                review,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: capture),
              const SizedBox(width: KairosSpacing.lg),
              Expanded(flex: 6, child: review),
            ],
          );
        },
      ),
    );
  }

  void _submitText() {
    ref.read(kairosRepositoryProvider.notifier).submitText(_textController.text);
    _textController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to review queue.')),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'txt',
        'mp3',
        'wav',
        'm4a',
      ],
    );

    if (!mounted || result == null) return;
    final fileNames = result.files.map((file) => file.name).join(', ');
    ref.read(kairosRepositoryProvider.notifier).submitText('Uploaded $fileNames');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploaded ${result.files.length} file(s).')),
    );
  }
}

class _CapturePanel extends StatelessWidget {
  const _CapturePanel({
    required this.textController,
    required this.inboxAddress,
    required this.onSubmit,
    required this.onPickFiles,
  });

  final TextEditingController textController;
  final String inboxAddress;
  final VoidCallback onSubmit;
  final VoidCallback onPickFiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Capture'),
        const SizedBox(height: KairosSpacing.md),
        TextField(
          controller: textController,
          minLines: 5,
          maxLines: 8,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Exam on September 15, bill due tomorrow, meeting at 4...',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 92),
              child: Icon(Icons.edit_note_rounded),
            ),
          ),
        ),
        const SizedBox(height: KairosSpacing.md),
        Wrap(
          spacing: KairosSpacing.sm,
          runSpacing: KairosSpacing.sm,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send'),
              onPressed: onSubmit,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload'),
              onPressed: onPickFiles,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Voice'),
              onPressed: onPickFiles,
            ),
          ],
        ),
        const SizedBox(height: KairosSpacing.lg),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mail_lock_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: KairosSpacing.sm),
                  Text('Kairos Inbox', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: KairosSpacing.sm),
              Text(
                inboxAddress,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: KairosSpacing.sm),
              Text(
                'Forward bills, tickets, datesheets, invites, and subscription emails.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewQueue extends ConsumerWidget {
  const _ReviewQueue({required this.items});

  final List<NeedsReviewItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Needs Review',
          subtitle: '${items.length} item(s)',
        ),
        const SizedBox(height: KairosSpacing.md),
        if (items.isEmpty)
          const KairosCard(child: Text('No new items.'))
        else
          for (final item in items) ...[
            _NeedsReviewCard(item: item),
            const SizedBox(height: KairosSpacing.sm),
          ],
      ],
    );
  }
}

class _NeedsReviewCard extends ConsumerWidget {
  const _NeedsReviewCard({required this.item});

  final NeedsReviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = confidenceColor(item.confidenceLevel);
    return KairosCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusPill(
                label: '${(item.confidence * 100).round()}%',
                icon: Icons.psychology_alt_rounded,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.xs),
          Text(
            item.source,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: KairosSpacing.md),
          for (final entry in item.extractedFields.entries) ...[
            _FieldRow(label: entry.key, value: entry.value),
            const SizedBox(height: KairosSpacing.xs),
          ],
          const SizedBox(height: KairosSpacing.md),
          Wrap(
            spacing: KairosSpacing.sm,
            runSpacing: KairosSpacing.sm,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: const Text('Confirm'),
                onPressed: () {
                  ref.read(kairosRepositoryProvider.notifier).confirmReview(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Memory created.')),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit flow ready for API wiring.')),
                  );
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Ignore'),
                onPressed: () {
                  ref.read(kairosRepositoryProvider.notifier).ignoreReview(item.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(width: KairosSpacing.sm),
        Expanded(child: Text(value)),
      ],
    );
  }
}
