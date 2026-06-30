import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(kairosRepositoryProvider);
    final profile = data.profile;

    return PageScaffold(
      title: 'Profile',
      subtitle: profile.email,
      actions: [
        Tooltip(
          message: 'Sign out',
          child: IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final identity = _IdentityPanel();
          final preferences = _PreferencesPanel();
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: KairosSpacing.lg),
                preferences,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: identity),
              const SizedBox(width: KairosSpacing.lg),
              Expanded(flex: 6, child: preferences),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(kairosRepositoryProvider).profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      profile.fullName.characters.first.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(width: KairosSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: KairosSpacing.xs),
                        Text(profile.occupation),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KairosSpacing.lg),
              _ProfileRow(label: 'Inbox', value: profile.kairosInboxAddress),
              _ProfileRow(label: 'Timezone', value: profile.timezone),
              _ProfileRow(label: 'Currency', value: profile.currency),
            ],
          ),
        ),
        const SizedBox(height: KairosSpacing.lg),
        const SectionHeader(title: 'Data Ownership'),
        const SizedBox(height: KairosSpacing.md),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can delete any memory, raw note, file, or extracted value.',
              ),
              const SizedBox(height: KairosSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete account'),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text('This starts the 48-hour account purge flow.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

class _PreferencesPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(kairosRepositoryProvider).profile;
    final themeMode = ref.watch(themeModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Preferences'),
        const SizedBox(height: KairosSpacing.md),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: KairosSpacing.sm),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.devices_rounded),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('Dark'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  ref.read(themeModeProvider.notifier).state = selection.first;
                },
              ),
              const Divider(height: KairosSpacing.xl),
              Text(
                'Daily briefing',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: KairosSpacing.sm),
              Wrap(
                spacing: KairosSpacing.sm,
                runSpacing: KairosSpacing.sm,
                children: [
                  for (final time in const ['07:00', '08:00', '09:00'])
                    ChoiceChip(
                      label: Text(time),
                      selected: profile.dailyBriefingTime == time,
                      onSelected: (_) {
                        ref.read(kairosRepositoryProvider.notifier).updateProfile(
                              dailyBriefingTime: time,
                            );
                      },
                    ),
                ],
              ),
              const Divider(height: KairosSpacing.xl),
              Text(
                'Notification intensity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: profile.notificationIntensity,
                onChanged: (value) {
                  ref.read(kairosRepositoryProvider.notifier).updateProfile(
                        notificationIntensity: value,
                      );
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Push notifications'),
                secondary: const Icon(Icons.notifications_active_outlined),
                value: profile.pushEnabled,
                onChanged: (value) {
                  ref.read(kairosRepositoryProvider.notifier).updateProfile(
                        pushEnabled: value,
                      );
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Email summaries'),
                secondary: const Icon(Icons.mark_email_read_outlined),
                value: profile.emailEnabled,
                onChanged: (value) {
                  ref.read(kairosRepositoryProvider.notifier).updateProfile(
                        emailEnabled: value,
                      );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KairosSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: KairosSpacing.sm),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
