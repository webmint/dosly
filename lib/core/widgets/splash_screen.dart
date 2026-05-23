/// Startup splash screen shown while app preferences hydrate.
///
/// The background colour is set to `colorScheme.surface` so the hand-off from
/// the native OS launch screen is seamless — both surfaces share the same
/// background colour, avoiding a visible flash between the two.
library;

import 'package:flutter/material.dart';

import '../../l10n/l10n_extensions.dart';

/// Stateless splash screen displayed during the app-preferences loading phase.
///
/// Uses `colorScheme.surface` as its background to match the native OS launch
/// screen, making the transition seamless. Renders a [CircularProgressIndicator]
/// and the localized [AppLocalizations.splashLoading] label.
class SplashScreen extends StatelessWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.splashLoading),
          ],
        ),
      ),
    );
  }
}
