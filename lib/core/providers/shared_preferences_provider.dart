/// Riverpod provider for [SharedPreferencesWithCache].
///
/// This provider is declared with a throwing placeholder so that it **must** be
/// overridden in the root `ProviderScope` (inside `main()`). Failing to
/// override it is a programmer error caught immediately at startup.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// Provides the application-wide [SharedPreferencesWithCache] instance.
///
/// Override this provider in the root `ProviderScope`:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     sharedPreferencesProvider.overrideWithValue(prefs),
///   ],
///   child: const DoslyApp(),
/// );
/// ```
@Riverpod(keepAlive: true)
SharedPreferencesWithCache sharedPreferences(Ref ref) =>
    throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main()',
    );
