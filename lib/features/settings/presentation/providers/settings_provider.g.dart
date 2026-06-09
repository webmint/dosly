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

/// Provides a [SetThemeMode] use case wired to the settings repository.

@ProviderFor(setThemeMode)
final setThemeModeProvider = SetThemeModeProvider._();

/// Provides a [SetThemeMode] use case wired to the settings repository.

final class SetThemeModeProvider
    extends $FunctionalProvider<SetThemeMode, SetThemeMode, SetThemeMode>
    with $Provider<SetThemeMode> {
  /// Provides a [SetThemeMode] use case wired to the settings repository.
  SetThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setThemeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setThemeModeHash();

  @$internal
  @override
  $ProviderElement<SetThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SetThemeMode create(Ref ref) {
    return setThemeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetThemeMode>(value),
    );
  }
}

String _$setThemeModeHash() => r'dcc6ced488bf6b189b12e96bef6ed48ba74dd9c7';

/// Provides a [SetUseSystemTheme] use case wired to the settings repository.

@ProviderFor(setUseSystemTheme)
final setUseSystemThemeProvider = SetUseSystemThemeProvider._();

/// Provides a [SetUseSystemTheme] use case wired to the settings repository.

final class SetUseSystemThemeProvider
    extends
        $FunctionalProvider<
          SetUseSystemTheme,
          SetUseSystemTheme,
          SetUseSystemTheme
        >
    with $Provider<SetUseSystemTheme> {
  /// Provides a [SetUseSystemTheme] use case wired to the settings repository.
  SetUseSystemThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setUseSystemThemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setUseSystemThemeHash();

  @$internal
  @override
  $ProviderElement<SetUseSystemTheme> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SetUseSystemTheme create(Ref ref) {
    return setUseSystemTheme(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetUseSystemTheme value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetUseSystemTheme>(value),
    );
  }
}

String _$setUseSystemThemeHash() => r'af1b82dc86b85531e608bf5674594698a81c733b';

/// Provides a [SetUseSystemLanguage] use case wired to the settings repository.

@ProviderFor(setUseSystemLanguage)
final setUseSystemLanguageProvider = SetUseSystemLanguageProvider._();

/// Provides a [SetUseSystemLanguage] use case wired to the settings repository.

final class SetUseSystemLanguageProvider
    extends
        $FunctionalProvider<
          SetUseSystemLanguage,
          SetUseSystemLanguage,
          SetUseSystemLanguage
        >
    with $Provider<SetUseSystemLanguage> {
  /// Provides a [SetUseSystemLanguage] use case wired to the settings repository.
  SetUseSystemLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setUseSystemLanguageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setUseSystemLanguageHash();

  @$internal
  @override
  $ProviderElement<SetUseSystemLanguage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SetUseSystemLanguage create(Ref ref) {
    return setUseSystemLanguage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetUseSystemLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetUseSystemLanguage>(value),
    );
  }
}

String _$setUseSystemLanguageHash() =>
    r'956067016c87df5c4bbff4345d11e364f8d230bd';

/// Provides a [SetManualLanguage] use case wired to the settings repository.

@ProviderFor(setManualLanguage)
final setManualLanguageProvider = SetManualLanguageProvider._();

/// Provides a [SetManualLanguage] use case wired to the settings repository.

final class SetManualLanguageProvider
    extends
        $FunctionalProvider<
          SetManualLanguage,
          SetManualLanguage,
          SetManualLanguage
        >
    with $Provider<SetManualLanguage> {
  /// Provides a [SetManualLanguage] use case wired to the settings repository.
  SetManualLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setManualLanguageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setManualLanguageHash();

  @$internal
  @override
  $ProviderElement<SetManualLanguage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SetManualLanguage create(Ref ref) {
    return setManualLanguage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetManualLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetManualLanguage>(value),
    );
  }
}

String _$setManualLanguageHash() => r'7aee4de463e8216e8cb1cf28eb2252da72c51ae3';

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).
// `name:` is load-bearing — codegen would otherwise strip the `Notifier`
// suffix and emit `settingsProvider`. Keep in sync with consumer call sites.

@ProviderFor(SettingsNotifier)
final settingsNotifierProvider = SettingsNotifierProvider._();

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).
// `name:` is load-bearing — codegen would otherwise strip the `Notifier`
// suffix and emit `settingsProvider`. Keep in sync with consumer call sites.
final class SettingsNotifierProvider
    extends $NotifierProvider<SettingsNotifier, AppSettings> {
  /// Notifier that manages [AppSettings] state.
  ///
  /// Reads initial settings synchronously from the repository cache and
  /// exposes methods to update individual preferences (theme and language).
  // `name:` is load-bearing — codegen would otherwise strip the `Notifier`
  // suffix and emit `settingsProvider`. Keep in sync with consumer call sites.
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

String _$settingsNotifierHash() => r'24db1c69a664cd355d35e5643f5b497865c32dec';

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).
// `name:` is load-bearing — codegen would otherwise strip the `Notifier`
// suffix and emit `settingsProvider`. Keep in sync with consumer call sites.

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

/// Broadcast stream of failures from [SettingsNotifier]'s save operations.
///
/// Surfaces the Left from each `saveX` mutator. The initial-load failure
/// emitted during [SettingsNotifier.build] is NOT delivered here — it is added
/// before any listener subscribes, and broadcast streams do not buffer
/// pre-subscription events (accepted — see spec 022 OQ-2).
///
/// Consumers (e.g. [SettingsScreen]) listen via `ref.listen` to surface
/// errors to the user — typically as a SnackBar. AutoDispose: re-subscribes
/// when a listener mounts and disposes when the last listener detaches. The
/// underlying [StreamController] lives on the kept-alive
/// [settingsNotifierProvider], so failures emitted while no listener is
/// subscribed are simply not buffered (the stream is event-driven, not state).

@ProviderFor(settingsErrors)
final settingsErrorsProvider = SettingsErrorsProvider._();

/// Broadcast stream of failures from [SettingsNotifier]'s save operations.
///
/// Surfaces the Left from each `saveX` mutator. The initial-load failure
/// emitted during [SettingsNotifier.build] is NOT delivered here — it is added
/// before any listener subscribes, and broadcast streams do not buffer
/// pre-subscription events (accepted — see spec 022 OQ-2).
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
  /// Broadcast stream of failures from [SettingsNotifier]'s save operations.
  ///
  /// Surfaces the Left from each `saveX` mutator. The initial-load failure
  /// emitted during [SettingsNotifier.build] is NOT delivered here — it is added
  /// before any listener subscribes, and broadcast streams do not buffer
  /// pre-subscription events (accepted — see spec 022 OQ-2).
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
