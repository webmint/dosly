/// Convenience extensions for accessing [AppLocalizations] from a
/// [BuildContext].
///
/// The sole purpose of this library is to centralize the null-assertion on
/// `AppLocalizations.of(context)` into exactly one call site so that widgets
/// can read localized strings without sprinkling `!` across the codebase.
/// Constitution §4.2.1 forbids `!` globally; spec §7 of feature 006-i18n
/// sanctions a single exception for [AppLocalizations.of], and this file is
/// that single site.
library;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Extensions on [BuildContext] for ergonomic [AppLocalizations] access.
extension AppLocalizationsContext on BuildContext {
  /// The active [AppLocalizations] for this context.
  ///
  /// Safe to use from any widget mounted under a correctly-configured
  /// [MaterialApp] (one with `localizationsDelegates:
  /// AppLocalizations.localizationsDelegates`). The underlying lookup is an
  /// O(1) `InheritedWidget` read, so calling `context.l10n` once per
  /// `build()` and binding it to a local is the conventional pattern.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
