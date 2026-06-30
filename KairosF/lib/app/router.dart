import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/memories/presentation/memories_screen.dart';
import '../features/memories/presentation/memory_detail_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/workflows/presentation/workflow_detail_screen.dart';
import '../shared/widgets/kairos_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/home' : '/login',
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!authState.isAuthenticated && !isAuthRoute) return '/login';
      if (authState.isAuthenticated && isAuthRoute) return '/home';
      if (state.matchedLocation == '/') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => KairosShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _fadePage(
              state,
              const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/inbox',
            pageBuilder: (context, state) => _fadePage(
              state,
              const InboxScreen(),
            ),
          ),
          GoRoute(
            path: '/memories',
            pageBuilder: (context, state) => _fadePage(
              state,
              const MemoriesScreen(),
            ),
          ),
          GoRoute(
            path: '/memory/:id',
            pageBuilder: (context, state) => _fadePage(
              state,
              MemoryDetailScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/workflow/:id',
            pageBuilder: (context, state) => _fadePage(
              state,
              WorkflowDetailScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => _fadePage(
              state,
              const NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _fadePage(
              state,
              const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            redirect: (context, state) => '/profile',
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
