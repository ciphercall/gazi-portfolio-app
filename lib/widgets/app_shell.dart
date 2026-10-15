import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/aurora.dart';
import 'aurora.dart';

/// The app's chrome: the aurora field, the page, and a persistent bottom bar.
///
/// The bar is the only navigation surface. A bottom bar carries an icon *and* a
/// word for every destination, which is exactly the rule the owner asked for —
/// a glyph-only tab bar would fail it.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = <({String path, String label, IconData icon})>[
    (path: '/', label: 'Home', icon: PhosphorIconsRegular.house),
    (path: '/experience', label: 'Career', icon: PhosphorIconsRegular.briefcase),
    (path: '/projects', label: 'Work', icon: PhosphorIconsRegular.squaresFour),
    (path: '/cv', label: 'CV', icon: PhosphorIconsRegular.filePdf),
    (path: '/contact', label: 'Contact', icon: PhosphorIconsRegular.chatCircle),
  ];

  int _indexFor(String location) {
    final normalised = location.endsWith('/') && location.length > 1
        ? location.substring(0, location.length - 1)
        : location;

    if (normalised == '/') return 0;
    for (var i = 1; i < _destinations.length; i++) {
      if (normalised.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFor(location);

    return AuroraBackground(
      intensity: 0.85,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(bottom: false, child: child),
        bottomNavigationBar: _Bar(
          index: index,
          onSelected: (next) => context.go(_destinations[next].path),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF20A1120),
        border: Border(top: BorderSide(color: Aurora.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < AppShell._destinations.length; i++)
                Expanded(
                  child: _Tab(
                    destination: AppShell._destinations[i],
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.destination, required this.selected, required this.onTap});

  final ({String path, String label, IconData icon}) destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = selected ? Aurora.teal : Aurora.faint;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              Container(
                width: 20,
                height: 2,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  gradient: Aurora.gradient(),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 8),
            Icon(destination.icon, size: 19, color: colour),
            const SizedBox(height: 3),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Aurora.body(
                10.5,
                weight: selected ? 600 : 500,
                color: colour,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
