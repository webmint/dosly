/// Unit tests for the pure formatter functions in medication_display.dart.
///
/// Uses a real [AppLocalizations] instance loaded synchronously via
/// [AppLocalizations.delegate.load] with the `en` locale — no widget tree
/// required.
library;

import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/pack_stock.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/widgets/medication_display.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  // ---------------------------------------------------------------------------
  // formatDose
  // ---------------------------------------------------------------------------
  group('formatDose', () {
    test('whole-number amount strips trailing .0', () {
      const dose = Dosage(amount: 20, unit: DoseUnit.mg);
      expect(formatDose(dose, l10n), '20 mg');
    });

    test('fractional amount preserves decimal places', () {
      const dose = Dosage(amount: 2.5, unit: DoseUnit.ml);
      expect(formatDose(dose, l10n), '2.5 ml');
    });

    test('null dose returns null', () {
      expect(formatDose(null, l10n), isNull);
    });

    test('tablet unit uses en abbreviation "tab"', () {
      const dose = Dosage(amount: 1, unit: DoseUnit.tablet);
      expect(formatDose(dose, l10n), '1 tab');
    });

    test('fractional whole-number edge case: 0.5 preserves decimal', () {
      const dose = Dosage(amount: 0.5, unit: DoseUnit.ml);
      expect(formatDose(dose, l10n), '0.5 ml');
    });
  });

  // ---------------------------------------------------------------------------
  // formatTimes
  // ---------------------------------------------------------------------------
  group('formatTimes', () {
    test('unsorted slots are sorted ascending before formatting', () {
      const slots = [
        TimeSlot(id: TimeSlotId('a'), minuteOfDay: 1230), // 20:30
        TimeSlot(id: TimeSlotId('b'), minuteOfDay: 480), // 08:00
      ];
      expect(formatTimes(slots), '08:00, 20:30');
    });

    test('single-digit hour is zero-padded', () {
      const slots = [
        TimeSlot(id: TimeSlotId('a'), minuteOfDay: 480), // 08:00
      ];
      expect(formatTimes(slots), '08:00');
    });

    test('midnight (minuteOfDay 0) renders as 00:00', () {
      const slots = [
        TimeSlot(id: TimeSlotId('a'), minuteOfDay: 0),
      ];
      expect(formatTimes(slots), '00:00');
    });

    test('last-minute-of-day (1439) renders as 23:59', () {
      const slots = [
        TimeSlot(id: TimeSlotId('a'), minuteOfDay: 1439),
      ];
      expect(formatTimes(slots), '23:59');
    });

    test('empty slot list returns empty string', () {
      expect(formatTimes([]), '');
    });

    test('multiple slots comma-joined with ", "', () {
      const slots = [
        TimeSlot(id: TimeSlotId('a'), minuteOfDay: 480), // 08:00
        TimeSlot(id: TimeSlotId('b'), minuteOfDay: 720), // 12:00
        TimeSlot(id: TimeSlotId('c'), minuteOfDay: 1200), // 20:00
      ];
      expect(formatTimes(slots), '08:00, 12:00, 20:00');
    });
  });

  // ---------------------------------------------------------------------------
  // formatStock
  // ---------------------------------------------------------------------------
  group('formatStock', () {
    test('returns localized stock string in en', () {
      const stock = PackStock(remaining: 18, total: 30, warnAt: 10);
      expect(formatStock(stock, l10n), '18 of 30 pcs');
    });

    test('null stock returns null', () {
      expect(formatStock(null, l10n), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // isLowStock
  // ---------------------------------------------------------------------------
  group('isLowStock', () {
    test('remaining == warnAt returns true (boundary)', () {
      const stock = PackStock(remaining: 10, total: 30, warnAt: 10);
      expect(isLowStock(stock), isTrue);
    });

    test('remaining below warnAt returns true', () {
      const stock = PackStock(remaining: 5, total: 30, warnAt: 10);
      expect(isLowStock(stock), isTrue);
    });

    test('remaining above warnAt returns false', () {
      const stock = PackStock(remaining: 18, total: 30, warnAt: 10);
      expect(isLowStock(stock), isFalse);
    });

    test('null stock returns false', () {
      expect(isLowStock(null), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // doseUnitAbbrev — exhaustive coverage for all DoseUnit values
  // ---------------------------------------------------------------------------
  group('doseUnitAbbrev', () {
    test('tablet → "tab"', () {
      expect(doseUnitAbbrev(DoseUnit.tablet, l10n), 'tab');
    });

    test('capsule → "cap"', () {
      expect(doseUnitAbbrev(DoseUnit.capsule, l10n), 'cap');
    });

    test('ml → "ml"', () {
      expect(doseUnitAbbrev(DoseUnit.ml, l10n), 'ml');
    });

    test('mg → "mg"', () {
      expect(doseUnitAbbrev(DoseUnit.mg, l10n), 'mg');
    });

    test('drops → "drops"', () {
      expect(doseUnitAbbrev(DoseUnit.drops, l10n), 'drops');
    });

    test('units → "IU"', () {
      expect(doseUnitAbbrev(DoseUnit.units, l10n), 'IU');
    });

    test('puff → "puff"', () {
      expect(doseUnitAbbrev(DoseUnit.puff, l10n), 'puff');
    });

    test('application → "dose"', () {
      expect(doseUnitAbbrev(DoseUnit.application, l10n), 'dose');
    });

    test('sachet → "sachet"', () {
      expect(doseUnitAbbrev(DoseUnit.sachet, l10n), 'sachet');
    });
  });
}
