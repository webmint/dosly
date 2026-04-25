/// Application shell — tabbed layout host for the `StatefulShellRoute`.
///
/// This library contains [AppShell], the sole adapter between go_router's
/// [StatefulNavigationShell] and the [AppBottomNav] widget.
///
/// Role:
/// * Hosts the shared bottom navigation bar for the tabbed branches of
///   [appRouter]'s `StatefulShellRoute`.
/// * Translates `StatefulNavigationShell.currentIndex` and
///   `StatefulNavigationShell.goBranch` into the plain `int`/`ValueChanged<int>`
///   parameters that [AppBottomNav] expects, keeping [AppBottomNav] itself
///   router-agnostic and trivially testable.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_bottom_nav.dart';

/// Shell widget that renders the shared tabbed app layout.
///
/// [AppShell] is constructed by go_router via the `StatefulShellRoute` builder
/// and receives a [StatefulNavigationShell] as its sole domain parameter.
/// It renders a [Scaffold] whose:
///
/// * `body` is the [navigationShell] itself (a [Widget] that displays the
///   active branch's navigator stack).
/// * `bottomNavigationBar` is [AppBottomNav] wired to the shell's active
///   branch index ([StatefulNavigationShell.currentIndex]) and branch-switching
///   callback ([StatefulNavigationShell.goBranch]).
///
/// Each branch provides its own `AppBar`; this shell intentionally omits one.
class AppShell extends StatelessWidget {
  /// Creates an [AppShell] for the given go_router [navigationShell].
  ///
  /// [navigationShell] is supplied automatically by go_router when the
  /// `StatefulShellRoute` builder invokes this constructor — it must not be
  /// null and is never constructed manually.
  const AppShell({required this.navigationShell, super.key});

  /// The go_router-supplied navigation shell for the active `StatefulShellRoute`.
  ///
  /// Acts as the `body` of the [Scaffold] and exposes:
  /// * [StatefulNavigationShell.currentIndex] — the zero-based index of the
  ///   currently active branch, forwarded to [AppBottomNav.selectedIndex].
  /// * [StatefulNavigationShell.goBranch] — called with the tapped destination
  ///   index, forwarded to [AppBottomNav.onDestinationSelected].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
      ),
    );
  }
}
