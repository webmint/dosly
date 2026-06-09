// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(sharedPreferencesInit)
final sharedPreferencesInitProvider = SharedPreferencesInitProvider._();

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

final class SharedPreferencesInitProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferencesWithCache>,
          SharedPreferencesWithCache,
          FutureOr<SharedPreferencesWithCache>
        >
    with
        $FutureModifier<SharedPreferencesWithCache>,
        $FutureProvider<SharedPreferencesWithCache> {
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
  SharedPreferencesInitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesInitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesInitHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferencesWithCache> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferencesWithCache> create(Ref ref) {
    return sharedPreferencesInit(ref);
  }
}

String _$sharedPreferencesInitHash() =>
    r'f5b6b158bfb3cf4e72457d71bdb30c74a27e829c';

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

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

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

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferencesWithCache,
          SharedPreferencesWithCache,
          SharedPreferencesWithCache
        >
    with $Provider<SharedPreferencesWithCache> {
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
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferencesWithCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferencesWithCache create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferencesWithCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferencesWithCache>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'f2b43e76162afdd7d5e9308c20f0f0cefde90913';
