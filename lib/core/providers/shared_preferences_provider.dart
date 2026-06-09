/// Riverpod providers for [SharedPreferencesWithCache].
///
/// This library exposes two providers that work together:
///
/// - [sharedPreferencesInit] — the async creation seam that builds the
///   app-wide [SharedPreferencesWithCache] instance. It is awaited (via
///   `AsyncValue`) by the `AppBootstrap` widget during startup.
/// - [sharedPreferences] — a synchronous, throwing placeholder. It exists so
///   the settings provider tree can read prefs synchronously. The
///   `AppBootstrap` widget injects the resolved value from
///   [sharedPreferencesInit] as an override for this provider; until then it
///   throws to surface a missing-override programmer error immediately.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_prefs_keys.dart';

part 'shared_preferences_provider.g.dart';

/// Asynchronously creates the application-wide [SharedPreferencesWithCache]
/// instance.
///
/// This is the async creation seam for the prefs instance. It is awaited (via
/// `AsyncValue`) by the `AppBootstrap` widget, which then injects the resolved
/// value as an override for the synchronous [sharedPreferences] provider. This
/// keeps `main()` non-blocking — prefs creation moves out of `main()` and into
/// the widget tree's startup phase.
///
/// The `allowList` mirrors the keys read by the settings feature: theme mode,
/// the system-theme toggle, the system-language toggle, and the manual
/// language selection.
@riverpod
Future<SharedPreferencesWithCache> sharedPreferencesInit(Ref ref) =>
    SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: settingsPrefsKeys,
      ),
    );

/// Provides the application-wide [SharedPreferencesWithCache] instance.
///
/// This provider uses a throwing placeholder — failing to inject an override
/// is a programmer error that surfaces immediately at startup. The override is
/// injected by `AppBootstrap`'s data branch (a nested [ProviderScope]) once
/// [sharedPreferencesInit] resolves:
///
/// ```dart
/// // Inside AppBootstrap.build — data branch
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
      'sharedPreferencesProvider must be overridden by AppBootstrap',
    );
