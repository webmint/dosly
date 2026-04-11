/// In-memory controller for the application's [ThemeMode].
///
/// Holds the current `ThemeMode` and notifies listeners on change. Used by
/// `DoslyApp` (see `lib/app.dart`) via a `ListenableBuilder` to drive
/// `MaterialApp.themeMode`.
///
/// Persistence is intentionally NOT handled here — the controller resets to
/// `ThemeMode.system` on every app restart. Persistence belongs to the future
/// Settings feature, which will use drift.
library;

import 'package:flutter/material.dart';

/// Controller for the current `ThemeMode`. Subclasses [ValueNotifier] so it
/// integrates cleanly with `ListenableBuilder` and any other Flutter listenable
/// consumer.
///
/// Default value is `ThemeMode.system`.
class ThemeController extends ValueNotifier<ThemeMode> {
  /// Creates a new controller with `ThemeMode.system` as the initial value.
  ThemeController() : super(ThemeMode.system);

  /// Sets the current mode and notifies listeners.
  ///
  /// Equivalent to assigning to [value], provided as a named method for
  /// readability at call sites.
  void setMode(ThemeMode mode) {
    value = mode;
  }

  /// Advances the current mode through the cycle:
  /// `system → light → dark → system`.
  void cycle() {
    value = switch (value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

/// Application-wide singleton instance of [ThemeController].
///
/// In-memory only — resets to `ThemeMode.system` on every app restart.
/// Persistence is the future Settings feature's responsibility.
final ThemeController themeController = ThemeController();
