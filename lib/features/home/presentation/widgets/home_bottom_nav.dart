/// Home feature — bottom navigation bar widget.
///
/// This library hosts [HomeBottomNav], a Material 3 [NavigationBar] with
/// three fixed destinations (Today, Meds, History) rendered with Lucide
/// icons.
///
/// The widget is intentionally inert for now:
///
/// * `selectedIndex` is fixed at `0` ("Today") and never changes.
/// * `onDestinationSelected` is a no-op — destinations are tappable so users
///   get Material ink/ripple feedback, but taps do NOT navigate anywhere.
///
/// A future spec will convert this widget to a `StatefulWidget` (or wire it
/// to a router-aware provider) once real routes exist behind each
/// destination.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// No-op callback for [NavigationBar.onDestinationSelected].
///
/// Declared as a top-level function so that callers can construct
/// [HomeBottomNav] with `const` — inline lambdas are not `const`-compatible.
void _noop(int _) {}

/// Material 3 bottom navigation bar for the home screen.
///
/// Renders a [NavigationBar] with three fixed destinations (Today, Meds,
/// History). The widget is currently presentational only — see the library
/// dartdoc for details on the inert behaviour and future plans.
class HomeBottomNav extends StatelessWidget {
  /// Creates the home screen bottom navigation bar.
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: _noop,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(LucideIcons.house),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.pill),
          label: 'Meds',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.activity),
          label: 'History',
        ),
      ],
    );
  }
}
