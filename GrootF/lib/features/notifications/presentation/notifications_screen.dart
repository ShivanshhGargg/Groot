import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/groot_models.dart';
import '../../../shared/data/groot_repository.dart';
import '../../../shared/widgets/groot_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/status_pill.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(grootRepositoryProvider).notifications;
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
                  ref.read(grootRepositoryProvider.notifier).markAllNotificationsRead();
                },
        ),
      ],
      child: notifications.isEmpty
          ? const GrootCard(child: Text('No notifications.'))
          : Column(
              children: [
                for (final notification in notifications) ...[
                  _NotificationCard(notification: notification),
                  const SizedBox(height: GrootSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final GrootNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorForType(notification.type);
    return GrootCard(
      borderColor: notification.read ? null : color.withOpacity(0.28),
      onTap: () {
        ref.read(grootRepositoryProvider.notifier).markNotificationRead(notification.id);
        context.go(notification.deepLink);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconForType(notification.type), color: color),
          const SizedBox(width: GrootSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: GrootSpacing.sm,
                  runSpacing: GrootSpacing.xs,
                  children: [
                    StatusPill(label: notification.type, color: color),
                    if (!notification.read)
                      const StatusPill(label: 'New', color: GrootColors.primary),
                  ],
                ),
                const SizedBox(height: GrootSpacing.sm),
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: GrootSpacing.xs),
                Text(notification.body),
                const SizedBox(height: GrootSpacing.xs),
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
    'Workflow' => GrootColors.warning,
    'Extraction' => GrootColors.critical,
    'Daily Briefing' => GrootColors.primary,
    _ => GrootColors.success,
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
