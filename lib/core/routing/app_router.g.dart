// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application router provider.
///
/// Returns the single app-wide [GoRouter] instance and binds its
/// [GoRouter.dispose] to the [ProviderScope] lifetime via `ref.onDispose`.
/// Consumed by `DoslyApp` via `ref.watch(appRouterProvider)`.
///
/// Tests that need a different route topology override this provider with
/// `appRouterProvider.overrideWith((ref) { final r = ...; ref.onDispose(r.dispose); return r; })`.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Application router provider.
///
/// Returns the single app-wide [GoRouter] instance and binds its
/// [GoRouter.dispose] to the [ProviderScope] lifetime via `ref.onDispose`.
/// Consumed by `DoslyApp` via `ref.watch(appRouterProvider)`.
///
/// Tests that need a different route topology override this provider with
/// `appRouterProvider.overrideWith((ref) { final r = ...; ref.onDispose(r.dispose); return r; })`.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Application router provider.
  ///
  /// Returns the single app-wide [GoRouter] instance and binds its
  /// [GoRouter.dispose] to the [ProviderScope] lifetime via `ref.onDispose`.
  /// Consumed by `DoslyApp` via `ref.watch(appRouterProvider)`.
  ///
  /// Tests that need a different route topology override this provider with
  /// `appRouterProvider.overrideWith((ref) { final r = ...; ref.onDispose(r.dispose); return r; })`.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'bc854dbf7d6fd1b10631b53b1d16833ec906effe';
