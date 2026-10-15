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
import 'theme/aurora.dart';
import 'widgets/app_shell.dart';

void main() {
  runApp(const GaziPortfolioApp());
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

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/experience',
          builder: (context, state) => const ExperienceScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
        ),
        GoRoute(
          path: '/projects/:slug',
          builder: (context, state) =>
              ProjectDetailScreen(slug: state.pathParameters['slug'] ?? ''),
        ),
        GoRoute(path: '/cv', builder: (context, state) => const CvScreen()),
        GoRoute(
          path: '/contact',
          builder: (context, state) => const ContactScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
