/// Riverpod provider for [SharedPreferencesWithCache].
///
/// This provider is declared with a throwing placeholder so that it **must** be
/// overridden in the root `ProviderScope` (inside `main()`). Failing to
/// override it is a programmer error caught immediately at startup.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);
