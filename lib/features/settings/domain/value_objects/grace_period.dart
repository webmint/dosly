/// Value object for the grace period setting.
///
/// Pure Dart value object of the settings domain model — no Flutter, drift, or
/// third-party imports (constitution §2.1). See [GracePeriod].
library;

/// The grace period: how long after marking an intake `taken` the user may undo
/// it back to `pending`.
///
/// Immutable and self-clamping: any [minutes] passed to the [GracePeriod]
/// factory is clamped into the inclusive range [minMinutes]..[maxMinutes], so a
/// constructed instance is always valid by construction. Equality is by value
/// on [minutes].
class GracePeriod {
  /// Private, unclamped constructor for known-valid or `const` values.
  ///
  /// Used only internally: by the clamping [GracePeriod] factory (which has
  /// already clamped the value) and by [defaultValue] (a compile-time constant).
  /// It is `const` so [defaultValue] can be used in `const` contexts such as a
  /// freezed `@Default`.
  const GracePeriod._(this.minutes);

  /// Creates a grace period, clamping [minutes] into
  /// [minMinutes]..[maxMinutes].
  ///
  /// Values below [minMinutes] become [minMinutes]; values above [maxMinutes]
  /// become [maxMinutes]. `int.clamp(int, int)` returns `int`, so [minutes]
  /// stays an `int`.
  factory GracePeriod(int minutes) =>
      GracePeriod._(minutes.clamp(minMinutes, maxMinutes));

  /// The grace period length in minutes. Always within
  /// [minMinutes]..[maxMinutes].
  final int minutes;

  /// The smallest allowed grace period, in minutes (inclusive).
  static const int minMinutes = 0;

  /// The largest allowed grace period, in minutes (inclusive).
  static const int maxMinutes = 30;

  /// The default grace period (5 minutes), usable in a `const` context.
  static const GracePeriod defaultValue = GracePeriod._(5);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GracePeriod && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => 'GracePeriod($minutes)';
}
