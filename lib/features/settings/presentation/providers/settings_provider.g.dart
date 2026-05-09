// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [SettingsRepository] implementation wired to the
/// application-wide [SharedPreferencesWithCache].

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// Provides the [SettingsRepository] implementation wired to the
/// application-wide [SharedPreferencesWithCache].

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// Provides the [SettingsRepository] implementation wired to the
  /// application-wide [SharedPreferencesWithCache].
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'96eeb7cec1454411236b528b78cf145945326caf';

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).

@ProviderFor(SettingsNotifier)
final settingsNotifierProvider = SettingsNotifierProvider._();

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).
final class SettingsNotifierProvider
    extends $NotifierProvider<SettingsNotifier, AppSettings> {
  /// Notifier that manages [AppSettings] state.
  ///
  /// Reads initial settings synchronously from the repository cache and
  /// exposes methods to update individual preferences (theme and language).
  SettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettings>(value),
    );
  }
}

String _$settingsNotifierHash() => r'7ae3e50f6aa4c930f55ddc49836ac2520c06be6b';

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).

abstract class _$SettingsNotifier extends $Notifier<AppSettings> {
  AppSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppSettings, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppSettings, AppSettings>,
              AppSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Broadcast stream of persistence failures from [SettingsNotifier].
///
/// Consumers (e.g. [SettingsScreen]) listen via `ref.listen` to surface
/// errors to the user — typically as a SnackBar. AutoDispose: re-subscribes
/// when a listener mounts and disposes when the last listener detaches. The
/// underlying [StreamController] lives on the kept-alive
/// [settingsNotifierProvider], so failures emitted while no listener is
/// subscribed are simply not buffered (the stream is event-driven, not state).

@ProviderFor(settingsErrors)
final settingsErrorsProvider = SettingsErrorsProvider._();

/// Broadcast stream of persistence failures from [SettingsNotifier].
///
/// Consumers (e.g. [SettingsScreen]) listen via `ref.listen` to surface
/// errors to the user — typically as a SnackBar. AutoDispose: re-subscribes
/// when a listener mounts and disposes when the last listener detaches. The
/// underlying [StreamController] lives on the kept-alive
/// [settingsNotifierProvider], so failures emitted while no listener is
/// subscribed are simply not buffered (the stream is event-driven, not state).

final class SettingsErrorsProvider
    extends $FunctionalProvider<AsyncValue<Failure>, Failure, Stream<Failure>>
    with $FutureModifier<Failure>, $StreamProvider<Failure> {
  /// Broadcast stream of persistence failures from [SettingsNotifier].
  ///
  /// Consumers (e.g. [SettingsScreen]) listen via `ref.listen` to surface
  /// errors to the user — typically as a SnackBar. AutoDispose: re-subscribes
  /// when a listener mounts and disposes when the last listener detaches. The
  /// underlying [StreamController] lives on the kept-alive
  /// [settingsNotifierProvider], so failures emitted while no listener is
  /// subscribed are simply not buffered (the stream is event-driven, not state).
  SettingsErrorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsErrorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsErrorsHash();

  @$internal
  @override
  $StreamProviderElement<Failure> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Failure> create(Ref ref) {
    return settingsErrors(ref);
  }
}

String _$settingsErrorsHash() => r'b3cd15355594a41fe978c3f9f9281cdbfb19c0dd';
