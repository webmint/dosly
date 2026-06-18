/// UI driver for the add-medication flow in the on-device integration-test
/// suite.
///
/// This file is purely a UI interaction layer — it drives the real widgets via
/// [WidgetTester] precise hit-testing. It does NOT boot the app, touch the
/// database, or declare a `main()`. A prior [bootAppWithTempDb] call must have
/// left the app on the Today screen before any function here is invoked.
///
/// Exports:
/// - [enterTimeViaKeyboard] — drives an open [showTimePicker] in keyboard
///   (text-input) mode.
/// - [addMedication] — performs the full add-medication modal flow for a
///   [MedFixture] and taps Save.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'medication_fixtures.dart';

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Formats [v] as a string without a trailing `.0` for whole numbers.
///
/// Examples: `1.5` → `"1.5"`, `2.0` → `"2"`, `0.5` → `"0.5"`.
String _formatAmount(double v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toString();

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Drives an already-open [showTimePicker] dialog into keyboard/text-input
/// mode and enters the given [hour] and [minute] strings, then confirms.
///
/// Switches to input mode by tapping the keyboard toggle icon
/// (`Icons.keyboard_outlined` or `Icons.keyboard`, whichever is present).
/// Uses semantic labels `"Hour"` and `"Minute"` to locate the text fields —
/// safer than positional indexing because other TextFields may be present
/// behind the dialog overlay.
///
/// The caller must call [WidgetTester.pumpAndSettle] after opening the dialog
/// and before this function. This function calls [WidgetTester.pumpAndSettle]
/// internally after confirming, so the caller does not need to do so
/// immediately after.
///
/// Example:
/// ```dart
/// await tester.tap(find.byType(ActionChip));
/// await tester.pumpAndSettle();
/// await enterTimeViaKeyboard(tester, hour: '08', minute: '30');
/// ```
Future<void> enterTimeViaKeyboard(
  WidgetTester tester, {
  required String hour,
  required String minute,
}) async {
  // Switch to text-input mode. The toggle icon is keyboard_outlined in newer
  // Material versions; fall back to keyboard if the outlined variant is absent.
  final keyboardOutlined = find.byIcon(Icons.keyboard_outlined);
  final keyboard = find.byIcon(Icons.keyboard);
  if (keyboardOutlined.evaluate().isNotEmpty) {
    await tester.tap(keyboardOutlined);
  } else if (keyboard.evaluate().isNotEmpty) {
    await tester.tap(keyboard);
  }
  await tester.pumpAndSettle();

  // Locate the hour and minute fields by their stable semantic labels.
  await tester.enterText(find.bySemanticsLabel('Hour'), hour);
  await tester.enterText(find.bySemanticsLabel('Minute'), minute);

  // Confirm the dialog.
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Performs the complete add-medication UI flow described by [f] and taps
/// Save.
///
/// Precondition: the app must be on the Today screen (i.e. [bootAppWithTempDb]
/// was called and settled successfully before this function is invoked). This
/// function navigates to the Meds screen, opens the add-medication modal,
/// fills every field according to [f], and taps Save. It does NOT assert any
/// database state — use [expectPersisted] in the calling test for that.
///
/// Navigation order:
/// 1. Tap the Meds bottom-nav icon → navigate Today → Meds.
/// 2. Tap the add-medication FAB → open the modal.
/// 3. Enter name, form, dose/quantity/stock, intake times, intake type,
///    course parameters.
/// 4. Tap Save.
///
/// Widget finders used (all stable, key-based where possible):
/// - Meds nav: `find.byIcon(LucideIcons.pill)`
/// - FAB: `find.byKey(const ValueKey('medsAddFab'))`
/// - Name: `find.byType(TextField)` (only TextField before form is chosen)
/// - Form toggle: `find.byKey(const ValueKey('medsFormPickerToggle'))`
/// - Form chip: `find.byKey(ValueKey('medsForm_<formKey>'))`
/// - Quantity stepper: `medsAddQtyIncrement` / `medsAddQtyValue`
/// - Stock fields: `medsAddStockRemaining`, `medsAddStockTotal`,
///   `medsAddStockWarn`
/// - Dose field: `medsAddDoseField`; unit dropdown: `medsAddDoseUnit`
/// - Add-time chip: `find.byType(ActionChip)` (sole ActionChip)
/// - Intake-type segmented button: `medsAddIntakeTypeSegmented`
/// - Course fields: `medsAddCourseDuration`, `medsAddCoursePause`
/// - Save: `find.widgetWithText(FilledButton, 'Save')`
Future<void> addMedication(WidgetTester tester, MedFixture f) async {
  // Step 1 — navigate to Meds screen.
  await tester.tap(find.byIcon(LucideIcons.pill));
  await tester.pumpAndSettle();

  // Step 2 — open the add-medication modal.
  await tester.tap(find.byKey(const ValueKey('medsAddFab')));
  await tester.pumpAndSettle();

  // Step 3 — enter medication name.
  // Before a form is selected, the only TextField in the tree is the name
  // field, so bare find.byType(TextField) is unambiguous.
  await tester.enterText(find.byType(TextField), f.name);
  await tester.pumpAndSettle();

  // Step 4 — select medication form.
  await tester.tap(find.byKey(const ValueKey('medsFormPickerToggle')));
  await tester.pumpAndSettle();
  final formChipFinder = find.byKey(ValueKey('medsForm_${f.formKey}'));
  await tester.ensureVisible(formChipFinder);
  await tester.tap(formChipFinder);
  await tester.pumpAndSettle();

  // Step 5 — dose / quantity / stock.
  if (f.isQuantityDose) {
    // Tablet / Capsule: use the quantity stepper.
    final qtyValueFinder = find.byKey(const ValueKey('medsAddQtyValue'));
    final incrementFinder = find.byKey(const ValueKey('medsAddQtyIncrement'));
    final target = _formatAmount(f.doseAmount ?? 1.0);

    // Tap increment until the displayed value matches the target.
    // Guard with ≤ 30 iterations to prevent an infinite loop.
    var iterations = 0;
    while (iterations < 30) {
      final currentWidget = tester.widget<Text>(qtyValueFinder);
      final currentValue = currentWidget.data ?? '';
      if (currentValue == target) break;
      await tester.tap(incrementFinder);
      await tester.pump();
      iterations++;
    }

    // Assert the stepper reached the target so a stuck stepper fails loudly
    // here instead of silently producing a wrong dose in the DB assertion.
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('medsAddQtyValue'))).data,
      target,
      reason: 'quantity stepper did not reach $target',
    );

    // Stock fields (only when the fixture tracks stock).
    final remaining = f.stockRemaining;
    final total = f.stockTotal;
    final warn = f.stockWarn;
    if (remaining != null) {
      await tester.ensureVisible(
        find.byKey(const ValueKey('medsAddStockRemaining')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('medsAddStockRemaining')),
        '$remaining',
      );
      if (total != null) {
        await tester.enterText(
          find.byKey(const ValueKey('medsAddStockTotal')),
          '$total',
        );
      }
      if (warn != null) {
        await tester.enterText(
          find.byKey(const ValueKey('medsAddStockWarn')),
          '$warn',
        );
      }
    }
  } else {
    final dose = f.doseAmount;
    if (dose != null) {
      // Syrup / Drops / Injection: text field + unit dropdown.
      await tester.ensureVisible(
        find.byKey(const ValueKey('medsAddDoseField')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('medsAddDoseField')),
        _formatAmount(dose),
      );

      final unitIndex = f.doseUnitIndex;
      if (unitIndex != null && unitIndex != 0) {
        await tester.tap(find.byKey(const ValueKey('medsAddDoseUnit')));
        await tester.pumpAndSettle();
        // Avoid null assertion — read into a local before using.
        final unit = f.doseUnitName;
        if (unit != null) {
          await tester.tap(find.text(unit).last);
        }
        await tester.pumpAndSettle();
      }
    }
    // Else: inhaler / cream / sachet — no dose or stock fields.
  }

  // Step 6 — intake times.
  for (final t in f.times) {
    await tester.ensureVisible(find.byType(ActionChip));
    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    await enterTimeViaKeyboard(
      tester,
      hour: t.hour.toString().padLeft(2, '0'),
      minute: t.minute.toString().padLeft(2, '0'),
    );
  }

  // Step 7 — intake type (course vs continuous).
  if (f.isCourse) {
    await tester.ensureVisible(
      find.byKey(const ValueKey('medsAddIntakeTypeSegmented')),
    );
    await tester.tap(find.byIcon(LucideIcons.repeat));
    await tester.pumpAndSettle();

    // Enter course parameters — avoid null assertions via local variables.
    final dur = f.durationDays;
    final pause = f.pauseDays;
    if (dur != null) {
      await tester.enterText(
        find.byKey(const ValueKey('medsAddCourseDuration')),
        '$dur',
      );
    }
    if (pause != null) {
      await tester.enterText(
        find.byKey(const ValueKey('medsAddCoursePause')),
        '$pause',
      );
    }
    await tester.pumpAndSettle();
  }
  // Continuous is the default — no tap required.

  // Step 8 — save.
  await tester.ensureVisible(find.byKey(const ValueKey('medsAddSaveButton')));
  await tester.tap(find.byKey(const ValueKey('medsAddSaveButton')));
  await tester.pumpAndSettle();
}
