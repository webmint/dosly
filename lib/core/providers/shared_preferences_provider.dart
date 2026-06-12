/// Riverpod providers for [SharedPreferencesWithCache].
///
/// This library exposes two providers that work together:
///
/// - [sharedPreferencesInit] — the async creation seam that builds the
///   app-wide [SharedPreferencesWithCache] instance. It is awaited (via
///   `AsyncValue`) by the `AppBootstrap` widget during startup.
/// - [sharedPreferences] — a synchronous accessor the settings provider tree
///   reads. It exposes the value resolved by [sharedPreferencesInit] via
///   `requireValue`. `AppBootstrap` only mounts the widgets that read it after
///   [sharedPreferencesInit] has resolved (its `data` branch), so the
///   synchronous read always succeeds; reading it before then is a programmer
///   error that surfaces immediately.
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
/// Returns the value resolved by [sharedPreferencesInit] via `requireValue`,
/// giving the settings provider tree a synchronous read. `AppBootstrap` only
/// mounts `DoslyApp` (and therefore the settings providers that read this) in
/// its `data` branch — after [sharedPreferencesInit] has resolved — so
/// `requireValue` always has a value. If this is read while
/// [sharedPreferencesInit] is still loading or in error, `requireValue` throws,
/// surfacing the programmer error immediately. Tests may still override this
/// provider directly with a fake or in-memory instance.
@Riverpod(keepAlive: true)
SharedPreferencesWithCache sharedPreferences(Ref ref) =>
    ref.watch(sharedPreferencesInitProvider).requireValue;
