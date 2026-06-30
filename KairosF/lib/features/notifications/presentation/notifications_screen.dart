import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/kairos_models.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/status_pill.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(kairosRepositoryProvider).notifications;
    final unread = notifications.where((notification) => !notification.read).length;

    return PageScaffold(
      title: 'Notifications',
      subtitle: '$unread unread',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Read all'),
          onPressed: notifications.isEmpty
              ? null
              : () {
                  ref.read(kairosRepositoryProvider.notifier).markAllNotificationsRead();
                },
        ),
      ],
      child: notifications.isEmpty
          ? const KairosCard(child: Text('No notifications.'))
          : Column(
              children: [
                for (final notification in notifications) ...[
                  _NotificationCard(notification: notification),
                  const SizedBox(height: KairosSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final KairosNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorForType(notification.type);
    return KairosCard(
      borderColor: notification.read ? null : color.withValues(alpha: 0.28),
      onTap: () {
        ref.read(kairosRepositoryProvider.notifier).markNotificationRead(notification.id);
        context.go(notification.deepLink);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconForType(notification.type), color: color),
          const SizedBox(width: KairosSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: KairosSpacing.sm,
                  runSpacing: KairosSpacing.xs,
                  children: [
                    StatusPill(label: notification.type, color: color),
                    if (!notification.read)
                      const StatusPill(label: 'New', color: KairosColors.primary),
                  ],
                ),
                const SizedBox(height: KairosSpacing.sm),
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: KairosSpacing.xs),
                Text(notification.body),
                const SizedBox(height: KairosSpacing.xs),
                Text(
                  notification.createdLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

Color _colorForType(String type) {
  return switch (type) {
    'Workflow' => KairosColors.warning,
    'Extraction' => KairosColors.critical,
    'Daily Briefing' => KairosColors.primary,
    _ => KairosColors.success,
  };
}

IconData _iconForType(String type) {
  return switch (type) {
    'Workflow' => Icons.route_rounded,
    'Extraction' => Icons.fact_check_outlined,
    'Daily Briefing' => Icons.wb_sunny_outlined,
    _ => Icons.notifications_rounded,
  };
}
