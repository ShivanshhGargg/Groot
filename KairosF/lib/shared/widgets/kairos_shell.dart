import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/auth/application/auth_controller.dart';
import '../data/kairos_repository.dart';

class KairosShell extends ConsumerWidget {
  const KairosShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 780) {
      return _MobileShell(child: child);
    }
    return _DesktopShell(child: child);
  }
}

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    final profile = ref.watch(kairosRepositoryProvider).profile;
    final unreadCount = ref
        .watch(kairosRepositoryProvider)
        .notifications
        .where((notification) => !notification.read)
        .length;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _goToIndex(context, index),
            leading: Padding(
              padding: const EdgeInsets.only(bottom: KairosSpacing.lg),
              child: Column(
                children: [
                  Image.asset(
                    'assets/brand/kairos-mark.png',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(height: KairosSpacing.sm),
                  Text(
                    'Kairos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: KairosSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Sign out',
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: () {
                            ref
                                .read(authControllerProvider.notifier)
                                .signOut();
                          },
                        ),
                      ),
                      const SizedBox(height: KairosSpacing.sm),
                      Text(
                        profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _destinations(unreadCount),
          ),
          VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    final unreadCount = ref
        .watch(kairosRepositoryProvider)
        .notifications
        .where((notification) => !notification.read)
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: KairosSpacing.md,
        title: Row(
          children: [
            Image.asset(
              'assets/brand/kairos-mark.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: KairosSpacing.sm),
            const Text('Kairos'),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Sign out',
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _goToIndex(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.move_to_inbox_outlined),
            selectedIcon: Icon(Icons.move_to_inbox_rounded),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Memory',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

List<NavigationRailDestination> _destinations(int unreadCount) {
  return [
    const NavigationRailDestination(
      icon: Icon(Icons.bolt_outlined),
      selectedIcon: Icon(Icons.bolt_rounded),
      label: Text('Home'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.move_to_inbox_outlined),
      selectedIcon: Icon(Icons.move_to_inbox_rounded),
      label: Text('Inbox'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.auto_stories_outlined),
      selectedIcon: Icon(Icons.auto_stories_rounded),
      label: Text('Memories'),
    ),
    NavigationRailDestination(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
      selectedIcon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_rounded),
      ),
      label: const Text('Notifications'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('Profile'),
    ),
  ];
}

int _selectedIndex(BuildContext context) {
  final path = GoRouterState.of(context).uri.path;
  if (path.startsWith('/inbox')) return 1;
  if (path.startsWith('/memories') ||
      path.startsWith('/memory') ||
      path.startsWith('/workflow')) {
    return 2;
  }
  if (path.startsWith('/notifications')) return 3;
  if (path.startsWith('/profile') || path.startsWith('/settings')) return 4;
  return 0;
}

void _goToIndex(BuildContext context, int index) {
  final destinations = ['/home', '/inbox', '/memories', '/notifications', '/profile'];
  context.go(destinations[index]);
}
