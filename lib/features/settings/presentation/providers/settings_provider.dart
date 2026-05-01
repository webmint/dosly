/// Riverpod providers for application settings.
///
/// Exposes [settingsRepositoryProvider] (wires the data layer) and
/// [settingsProvider] (the [NotifierProvider] that holds [AppSettings]
/// state and persists changes through the repository).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/settings_local_data_source.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';

/// Provides the [SettingsRepository] implementation wired to the
/// application-wide [SharedPreferencesWithCache].
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dataSource = SettingsLocalDataSource(prefs);
  return SettingsRepositoryImpl(dataSource);
});

/// Provides the current [AppSettings] and exposes mutation methods.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Notifier that manages [AppSettings] state.
///
/// Reads initial settings synchronously from the repository cache and
/// exposes methods to update individual preferences (theme and language).
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.load();
  }

  /// Updates the manual theme mode, persists it, and notifies listeners.
  ///
  /// Only [AppThemeMode.light] and [AppThemeMode.dark] are valid values
  /// for the manual override (the enum has no `system` value by design —
  /// the orthogonal [AppSettings.useSystemTheme] flag owns that concept).
  /// On persistence failure the in-memory state is not updated so the UI
  /// stays consistent with what was actually saved.
  Future<void> setThemeMode(AppThemeMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveThemeMode(mode);
    result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint('Settings: persistence failed — $failure');
        }
      },
      (_) {
        state = state.copyWith(manualThemeMode: mode);
      },
    );
  }

  /// Updates whether the app should follow the device system theme, persists
  /// the choice, and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated.
  Future<void> setUseSystemTheme(bool value) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveUseSystemTheme(value);
    result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint('Settings: persistence failed — $failure');
        }
      },
      (_) {
        state = state.copyWith(useSystemTheme: value);
      },
    );
  }

  /// Updates whether the app should follow the device language, persists the
  /// choice, and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated.
  Future<void> setUseSystemLanguage(bool value) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveUseSystemLanguage(value);
    result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint('Settings: persistence failed — $failure');
        }
      },
      (_) {
        state = state.copyWith(useSystemLanguage: value);
      },
    );
  }

  /// Updates the manual language, persists it, and notifies listeners.
  ///
  /// On persistence failure the in-memory state is not updated.
  Future<void> setManualLanguage(AppLanguage language) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveManualLanguage(language);
    result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint('Settings: persistence failed — $failure');
        }
      },
      (_) {
        state = state.copyWith(manualLanguage: language);
      },
    );
  }
}
