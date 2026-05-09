/// Riverpod providers for application settings.
///
/// Exposes [settingsRepositoryProvider] (wires the data layer) and
/// [settingsNotifierProvider] (the notifier that holds [AppSettings] state
/// and persists changes through the repository).
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

part 'settings_provider.g.dart';

/// Provides the [SettingsRepository] implementation wired to the
/// application-wide [SharedPreferencesWithCache].
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dataSource = SettingsLocalDataSource(prefs);
  return SettingsRepositoryImpl(dataSource);
}

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).
@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')
class SettingsNotifier extends _$SettingsNotifier {
  late final StreamController<Failure> _errors;

  /// Broadcast stream of [Failure]s emitted by the four save mutators.
  ///
  /// Each Left from [SettingsRepository.saveX] is forwarded to this stream
  /// so a UI surface (e.g. [SettingsScreen]) can react via
  /// [settingsErrorsProvider]. The state itself stays consistent with what
  /// was actually persisted — failures do not roll the in-memory state
  /// back. The controller is closed automatically when the notifier is
  /// disposed.
  Stream<Failure> get errors => _errors.stream;

  @override
  AppSettings build() {
    _errors = StreamController<Failure>.broadcast();
    ref.onDispose(_errors.close);
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.load();
  }

  /// Updates the manual theme mode, persists it, and notifies listeners.
  ///
  /// Only [AppThemeMode.light] and [AppThemeMode.dark] are valid values
  /// for the manual override (the enum has no `system` value by design —
  /// the orthogonal [AppSettings.useSystemTheme] flag owns that concept).
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setThemeMode(AppThemeMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveThemeMode(mode);
    result.fold(
      (failure) => _errors.add(failure),
      (_) {
        state = state.copyWith(manualThemeMode: mode);
      },
    );
  }

  /// Updates whether the app should follow the device system theme, persists
  /// the choice, and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setUseSystemTheme(bool value) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveUseSystemTheme(value);
    result.fold(
      (failure) => _errors.add(failure),
      (_) {
        state = state.copyWith(useSystemTheme: value);
      },
    );
  }

  /// Updates whether the app should follow the device language, persists the
  /// choice, and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setUseSystemLanguage(bool value) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveUseSystemLanguage(value);
    result.fold(
      (failure) => _errors.add(failure),
      (_) {
        state = state.copyWith(useSystemLanguage: value);
      },
    );
  }

  /// Updates the manual language, persists it, and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated and the
  /// failure is forwarded to [settingsErrorsProvider] so the UI can surface it.
  Future<void> setManualLanguage(AppLanguage language) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveManualLanguage(language);
    result.fold(
      (failure) => _errors.add(failure),
      (_) {
        state = state.copyWith(manualLanguage: language);
      },
    );
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
@riverpod
Stream<Failure> settingsErrors(Ref ref) {
  return ref.watch(settingsNotifierProvider.notifier).errors;
}
