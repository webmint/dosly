/// Error screen shown when SharedPreferences hydration fails at startup.
///
/// The widget is provider-agnostic: the retry behaviour is injected by the
/// caller via [PrefsLoadErrorScreen.onRetry], keeping the widget testable in
/// isolation without any Riverpod setup.
library;

import 'package:flutter/material.dart';

import '../../l10n/l10n_extensions.dart';

/// Stateless error screen displayed when app-preferences loading fails.
///
/// Shown when [SharedPreferences] hydration throws during startup. The only
/// recovery action is the localized Retry [FilledButton], which invokes the
/// [onRetry] callback supplied by the caller. The widget is provider-agnostic
/// — retry behaviour is injected externally, keeping it testable in isolation.
class PrefsLoadErrorScreen extends StatelessWidget {
  /// Callback invoked when the user taps the Retry button.
  ///
  /// Injected by the caller so this widget remains free of any provider or
  /// state-management dependency. Typically wires up to a provider
  /// `ref.invalidate` or a repository retry method in the parent widget.
  final VoidCallback onRetry;

  /// Creates a [PrefsLoadErrorScreen].
  ///
  /// [onRetry] is required and must not be null.
  const PrefsLoadErrorScreen({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.prefsLoadErrorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.prefsLoadRetry),
            ),
          ],
        ),
      ),
    );
  }
}
