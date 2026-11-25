import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'screens/contact_screen.dart';
import 'screens/cv_screen.dart';
import 'screens/experience_screen.dart';
import 'screens/home_screen.dart';
import 'screens/project_detail_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/updates_screen.dart';
import 'theme/aurora.dart';
import 'widgets/app_shell.dart';
import 'widgets/update_gate.dart';

void main() {
  runApp(const UpdateGate());
}

/// Portfolio companion app.
///
/// Read-only by design: everything here is served from `/api/v1`, and the app
/// keeps working from its last good snapshot when the stack is unreachable.
class GaziPortfolioApp extends StatelessWidget {
  const GaziPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PortfolioRepository()..bootstrap(),
      child: MaterialApp.router(
        title: 'Gazi Monir-Uz-Zaman',
        debugShowCheckedModeBanner: false,
        theme: buildAuroraTheme(),
        routerConfig: _router,
        // Long user text stays readable rather than exploding a layout.
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Shared route transition: a short fade and a 1.5% rise. Reduced motion keeps
/// the child untouched — navigation must never depend on the animation.
Page<void> _page(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: Aurora.normal,
    reverseTransitionDuration: Aurora.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

      final curved = CurvedAnimation(parent: animation, curve: Aurora.easeAurora);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _page(const HomeScreen()),
        ),
        GoRoute(
          path: '/experience',
          pageBuilder: (context, state) => _page(const ExperienceScreen()),
        ),
        GoRoute(
          path: '/projects',
          pageBuilder: (context, state) => _page(const ProjectsScreen()),
        ),
        GoRoute(
          path: '/projects/:slug',
          pageBuilder: (context, state) => _page(
            ProjectDetailScreen(slug: state.pathParameters['slug'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/cv',
          pageBuilder: (context, state) => _page(const CvScreen()),
        ),
        GoRoute(
          path: '/updates',
          pageBuilder: (context, state) => _page(const UpdatesScreen()),
        ),
        GoRoute(
          path: '/contact',
          pageBuilder: (context, state) => _page(const ContactScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _page(const SettingsScreen()),
        ),
      ],
    ),
  ],
);
