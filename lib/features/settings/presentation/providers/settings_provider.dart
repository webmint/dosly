/// Riverpod providers for application settings.
///
/// Exposes [settingsRepositoryProvider] (wires the data layer), the four use
/// case providers ([setThemeModeProvider], [setUseSystemThemeProvider],
/// [setUseSystemLanguageProvider], [setManualLanguageProvider]) that the
/// notifier delegates through, and [settingsNotifierProvider] (the notifier
/// that holds [AppSettings] state and persists changes via the use cases).
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/settings_local_data_source.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/set_manual_language.dart';
import '../../domain/usecases/set_theme_mode.dart';
import '../../domain/usecases/set_use_system_language.dart';
import '../../domain/usecases/set_use_system_theme.dart';

part 'settings_provider.g.dart';

/// Provides the [SettingsRepository] implementation wired to the
/// application-wide [SharedPreferencesWithCache].
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dataSource = SettingsLocalDataSource(prefs);
  return SettingsRepositoryImpl(dataSource);
}

/// Provides a [SetThemeMode] use case wired to the settings repository.
@riverpod
SetThemeMode setThemeMode(Ref ref) =>
    SetThemeMode(ref.watch(settingsRepositoryProvider));

/// Provides a [SetUseSystemTheme] use case wired to the settings repository.
@riverpod
SetUseSystemTheme setUseSystemTheme(Ref ref) =>
    SetUseSystemTheme(ref.watch(settingsRepositoryProvider));

/// Provides a [SetUseSystemLanguage] use case wired to the settings repository.
@riverpod
SetUseSystemLanguage setUseSystemLanguage(Ref ref) =>
    SetUseSystemLanguage(ref.watch(settingsRepositoryProvider));

/// Provides a [SetManualLanguage] use case wired to the settings repository.
@riverpod
SetManualLanguage setManualLanguage(Ref ref) =>
    SetManualLanguage(ref.watch(settingsRepositoryProvider));

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).
// `name:` is load-bearing — codegen would otherwise strip the `Notifier`
// suffix and emit `settingsProvider`. Keep in sync with consumer call sites.
@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')
class SettingsNotifier extends _$SettingsNotifier {
  // Not `late final`: Riverpod re-runs build() on the same notifier instance
  // when a watched dependency changes, and build() reassigns this field — a
  // `final` would throw LateInitializationError on the second build.
  late StreamController<Failure> _errors;

  /// Broadcast stream of [Failure]s from the four save mutators.
  ///
  /// Each Left returned by [SettingsRepository] `saveX` is forwarded here so a
  /// UI surface (e.g. [SettingsScreen]) can react via [settingsErrorsProvider].
  /// The state itself stays consistent with what was actually persisted (or the
  /// default fallback on load failure) — failures do not roll the in-memory
  /// state back. The controller is closed automatically when the notifier is
  /// disposed.
  ///
  /// NOTE: the initial-load failure emitted by [build] is NOT observable here.
  /// `build()` adds it before any listener can subscribe, and a broadcast
  /// stream does not buffer pre-subscription events (accepted behaviour — see
  /// spec 022 OQ-2). Only post-startup save failures reach a mounted listener.
  Stream<Failure> get errors => _errors.stream;

  @override
  AppSettings build() {
    _errors = StreamController<Failure>.broadcast();
    ref.onDispose(_errors.close);
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.load().fold((failure) {
      // No listener is subscribed at build() time, so this emit reaches no
      // one (broadcast streams don't buffer) — see the [errors] getter
      // dartdoc / spec 022 OQ-2. The default-state fallback below is the
      // observable safety net.
      _errors.add(failure);
      return const AppSettings();
    }, (settings) => settings);
  }

  /// Updates the manual theme mode, persists it, and notifies listeners.
  ///
  /// Only [AppThemeMode.light] and [AppThemeMode.dark] are valid values
  /// for the manual override (the enum has no `system` value by design —
  /// the orthogonal [AppSettings.useSystemTheme] flag owns that concept).
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setThemeMode(AppThemeMode mode) async {
    final result = await ref.read(setThemeModeProvider).call(mode);
    result.fold((failure) => _errors.add(failure), (_) {
      state = state.copyWith(manualThemeMode: mode);
    });
  }

  /// Updates whether the app should follow the device system theme, persists
  /// the choice atomically (pre-filling the manual override from
  /// [currentDeviceMode] when toggling OFF), and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setUseSystemTheme(
    bool value, {
    required AppThemeMode currentDeviceMode,
  }) async {
    final result = await ref
        .read(setUseSystemThemeProvider)
        .call(value: value, currentDeviceMode: currentDeviceMode);
    result.fold((failure) => _errors.add(failure), (_) {
      if (!value) {
        state = state.copyWith(
          manualThemeMode: currentDeviceMode,
          useSystemTheme: false,
        );
      } else {
        state = state.copyWith(useSystemTheme: true);
      }
    });
  }

  /// Updates whether the app should follow the device language, persists the
  /// choice atomically (pre-filling the manual override from
  /// [currentDeviceLanguage] when toggling OFF), and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setUseSystemLanguage(
    bool value, {
    required AppLanguage currentDeviceLanguage,
  }) async {
    final result = await ref
        .read(setUseSystemLanguageProvider)
        .call(value: value, currentDeviceLanguage: currentDeviceLanguage);
    result.fold((failure) => _errors.add(failure), (_) {
      if (!value) {
        state = state.copyWith(
          manualLanguage: currentDeviceLanguage,
          useSystemLanguage: false,
        );
      } else {
        state = state.copyWith(useSystemLanguage: true);
      }
    });
  }

  /// Updates the manual language, persists it, and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setManualLanguage(AppLanguage language) async {
    final result = await ref.read(setManualLanguageProvider).call(language);
    result.fold((failure) => _errors.add(failure), (_) {
      state = state.copyWith(manualLanguage: language);
    });
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
/// errors to the user — typically as a SnackBar. This wrapper is autoDispose:
/// it re-runs (re-reading the same long-lived stream) as listeners come and go.
/// The broadcast [StreamController] itself lives for the lifetime of the
/// kept-alive [settingsNotifierProvider] and is never re-created per listener,
/// so failures emitted while no listener is subscribed are simply not buffered
/// (the stream is event-driven, not state).
@riverpod
Stream<Failure> settingsErrors(Ref ref) {
  return ref.watch(settingsNotifierProvider.notifier).errors;
}
