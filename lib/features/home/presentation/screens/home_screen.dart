/// Home feature — placeholder main screen for the dosly MVP.
///
/// This library hosts [HomeScreen], the first screen users see after launch.
/// It is intentionally minimal while the real main-screen feature is being
/// built out; see `specs/002-main-screen/spec.md` for the full plan.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';

/// Placeholder main screen shown at the app's root route.
///
/// Displays a Material 3 [AppBar] with the app title "Dosly", a settings
/// gear [IconButton] that navigates to `/settings`, and an
/// `outlineVariant`-coloured bottom [Divider] border.
///
/// The body renders a centered "Hello World" label with a temporary
/// "Theme preview" [OutlinedButton] below it that navigates to the theme
/// preview route via `context.push('/theme-preview')`.
///
/// The "Theme preview" button is temporary dev scaffolding and is scheduled
/// for removal post-MVP together with the `lib/features/theme_preview/`
/// feature — see `specs/002-main-screen/spec.md` §6 and §8 for the removal
/// plan and rationale.
///
/// The bottom navigation bar is provided by the routing shell
/// (`lib/core/routing/app_shell.dart`) at the app level, not by [HomeScreen].
class HomeScreen extends StatelessWidget {
  /// Creates the placeholder home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosly'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            tooltip: context.l10n.settingsTooltip,
            icon: const Icon(LucideIcons.settings),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hello World'),
            const SizedBox(height: 24),
            // TODO(post-mvp): remove this dev entry point when
            // lib/features/theme_preview/ is deleted —
            // see specs/002-main-screen/spec.md §6 and §8.
            OutlinedButton(
              onPressed: () => context.push('/theme-preview'),
              child: const Text('Theme preview'),
            ),
          ],
        ),
      ),
    );
  }
}
