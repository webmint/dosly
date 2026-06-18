/// Pure formatter functions that build medication-tile subtitle segments.
///
/// All functions are stateless and free of side effects. They accept domain
/// entities and an [AppLocalizations] instance, returning ready-to-display
/// strings (or `null` when the segment is absent). The tile caller joins
/// non-null segments with " · ".
///
/// These live in `presentation/` rather than `domain/` because they depend on
/// both l10n (Flutter) and time formatting — not allowed in the pure-Dart
/// domain layer (constitution §2.1).
library;

import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/pack_stock.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/l10n/app_localizations.dart';

/// Returns a human-readable dose string such as `"20 mg"` or `"2.5 ml"`.
///
/// The numeric [amount] is formatted without a trailing `.0` for whole numbers
/// (e.g. `20.0` → `"20"`, `2.5` → `"2.5"`). The unit abbreviation is
/// resolved via [doseUnitAbbrev].
///
/// Returns `null` when [dose] is `null` so the caller can omit the segment.
String? formatDose(Dosage? dose, AppLocalizations l10n) {
  if (dose == null) return null;
  final amount = dose.amount;
  final amountStr =
      amount == amount.roundToDouble()
          ? amount.toInt().toString()
          : amount.toString();
  final unitStr = doseUnitAbbrev(dose.unit, l10n);
  return '$amountStr $unitStr';
}

/// Returns a comma-separated, zero-padded 24-hour time string for each slot.
///
/// Slots are sorted ascending by [TimeSlot.minuteOfDay] before formatting.
/// Each `minuteOfDay` is rendered as `HH:mm` (e.g. `480` → `"08:00"`,
/// `1230` → `"20:30"`). An empty [slots] list returns an empty string `""`.
String formatTimes(List<TimeSlot> slots) {
  if (slots.isEmpty) return '';
  final sorted = List<TimeSlot>.from(slots)
    ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
  return sorted.map((slot) {
    final h = (slot.minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final m = (slot.minuteOfDay % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }).join(', ');
}

/// Returns a localized stock string such as `"18 of 30 pcs"`.
///
/// Delegates to [AppLocalizations.medsListStock] using [PackStock.remaining]
/// and [PackStock.total]. Returns `null` when [stock] is `null` so the caller
/// can omit the segment.
String? formatStock(PackStock? stock, AppLocalizations l10n) {
  if (stock == null) return null;
  return l10n.medsListStock(stock.remaining, stock.total);
}

/// Returns `true` when the stock level is at or below the low-stock threshold.
///
/// A `null` [stock] is treated as "no stock tracking" and returns `false`.
bool isLowStock(PackStock? stock) {
  if (stock == null) return false;
  return stock.remaining <= stock.warnAt;
}

/// Maps a [DoseUnit] to its localized abbreviation string.
///
/// The switch is exhaustive — the compiler enforces that every [DoseUnit]
/// value is handled without a `default:` fallback.
String doseUnitAbbrev(DoseUnit unit, AppLocalizations l10n) {
  return switch (unit) {
    DoseUnit.tablet => l10n.doseUnitTablet,
    DoseUnit.capsule => l10n.doseUnitCapsule,
    DoseUnit.ml => l10n.doseUnitMl,
    DoseUnit.mg => l10n.doseUnitMg,
    DoseUnit.drops => l10n.doseUnitDrops,
    DoseUnit.units => l10n.doseUnitUnits,
    DoseUnit.puff => l10n.doseUnitPuff,
    DoseUnit.application => l10n.doseUnitApplication,
    DoseUnit.sachet => l10n.doseUnitSachet,
  };
}
