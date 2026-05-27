/// Application-wide bottom navigation bar widget.
///
/// This library hosts [AppBottomNav], a router-agnostic Material 3
/// [NavigationBar] with three fixed destinations (Today, Meds, History)
/// rendered with Lucide icons.
///
/// The widget's active state and tap handling are entirely external:
///
/// * `selectedIndex` is supplied by the caller (typically the routing shell
///   at `lib/core/routing/app_shell.dart`).
/// * `onDestinationSelected` is supplied by the caller and forwarded directly
///   to [NavigationBar.onDestinationSelected].
/// * Renders a 1-px top divider (`ColorScheme.outlineVariant` via the ambient
///   `DividerTheme`) matching the HTML design template's `.bot-nav` top border.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n_extensions.dart';

/// Material 3 bottom navigation bar for the app.
///
/// Renders a [NavigationBar] with three fixed destinations (Today, Meds,
/// History). The widget is router-agnostic — the active tab index and
/// navigation callback are provided by the parent, typically the routing
/// shell at `lib/core/routing/app_shell.dart`.
///
/// Parameters:
/// * [selectedIndex] — the zero-based index of the currently active
///   destination; forwarded to [NavigationBar.selectedIndex].
/// * [onDestinationSelected] — called with the tapped destination index;
///   forwarded to [NavigationBar.onDestinationSelected].
class AppBottomNav extends StatelessWidget {
  /// Creates the app bottom navigation bar.
  ///
  /// Both [selectedIndex] and [onDestinationSelected] are required and must
  /// be provided by the parent (typically the routing shell).
  const AppBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// The index of the currently selected destination (0 = Today, 1 = Meds,
  /// 2 = History).
  final int selectedIndex;

  /// Called when the user taps a destination.
  ///
  /// Receives the zero-based index of the tapped destination.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Divider(height: 1, thickness: 1),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(LucideIcons.house),
              label: l.bottomNavToday,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.pill),
              label: l.bottomNavMeds,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.activity),
              label: l.bottomNavHistory,
            ),
          ],
        ),
      ],
    );
  }
}
