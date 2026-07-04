/// Value object for the intake window setting.
///
/// Pure Dart value object of the settings domain model — no Flutter, drift, or
/// third-party imports (constitution §2.1). See [IntakeWindow].
library;

/// The intake window: how long an intake stays `pending` after its scheduled
/// time before it auto-transitions to `missed`.
///
/// Immutable and self-clamping: any [minutes] passed to the [IntakeWindow]
/// factory is clamped into the inclusive range [minMinutes]..[maxMinutes], so a
/// constructed instance is always valid by construction. Equality is by value
/// on [minutes].
class IntakeWindow {
  /// Private, unclamped constructor for known-valid or `const` values.
  ///
  /// Used only internally: by the clamping [IntakeWindow] factory (which has
  /// already clamped the value) and by [defaultValue] (a compile-time constant).
  /// It is `const` so [defaultValue] can be used in `const` contexts such as a
  /// freezed `@Default`.
  const IntakeWindow._(this.minutes);

  /// Creates an intake window, clamping [minutes] into
  /// [minMinutes]..[maxMinutes].
  ///
  /// Values below [minMinutes] become [minMinutes]; values above [maxMinutes]
  /// become [maxMinutes]. `int.clamp(int, int)` returns `int`, so [minutes]
  /// stays an `int`.
  factory IntakeWindow(int minutes) =>
      IntakeWindow._(minutes.clamp(minMinutes, maxMinutes));

  /// The window length in minutes. Always within [minMinutes]..[maxMinutes].
  final int minutes;

  /// The smallest allowed intake window, in minutes (inclusive).
  static const int minMinutes = 15;

  /// The largest allowed intake window, in minutes (inclusive).
  static const int maxMinutes = 240;

  /// The default intake window (120 minutes), usable in a `const` context.
  static const IntakeWindow defaultValue = IntakeWindow._(120);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntakeWindow && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => 'IntakeWindow($minutes)';
}
