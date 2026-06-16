// Tests for the AddMedicationModal.
// spec 011-meds-add-fab    — AppBar back-arrow / title / typography.
// spec 026-add-med-name-input — body TextField and Save button structure.
// spec 027-med-form-picker — medication-form picker (collapse/expand/select).
// spec 028-form-dependent-fields — dose/quantity/stock conditional fields.
// spec 029-intake-time-chips — intake-time chips (add/edit/remove/sort/duplicate).
// spec 030-intake-type — intake-type segmented button and course-parameters card.
import 'package:clock/clock.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/meds/presentation/widgets/add_medication_modal.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Builds a widget tree rendering [AddMedicationModal] directly as [home].
///
/// The modal IS its own [Scaffold], so it does not need to be wrapped.
Widget _harness({required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: resolveAppLocale,
    home: const AddMedicationModal(),
  );
}

/// Interacts with an open [showTimePicker] dialog in keyboard/text-input mode.
///
/// Switches to input mode via the keyboard toggle icon (if not already in that
/// mode), enters [hour] and [minute] into their respective text fields, then
/// taps the OK button.  Callers must call [WidgetTester.pumpAndSettle] after
/// the dialog has been opened and before calling this helper, and again after
/// it returns to allow the dialog to close.
///
/// Implementation note: after switching to text-input mode the hour and minute
/// fields are located by their Material semantic labels ("Hour" and "Minute"),
/// which are stable English-locale identifiers set by the framework on the
/// time-picker input fields.  This is safer than positional indexing because
/// the full widget tree contains additional TextFields (e.g. the modal's
/// medication-name field rendered behind the dialog overlay), so a bare
/// [find.byType] index would be order-dependent and fragile.
Future<void> _pickTimeInDialog(
  WidgetTester tester, {
  required String hour,
  required String minute,
}) async {
  // Switch to text-input mode.  The toggle icon is keyboard_outlined in newer
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

void main() {
  group('AddMedicationModal locale switching', () {
    testWidgets("renders 'Add medication' under Locale('en')", (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Add medication'), findsOneWidget);
    });

    testWidgets("renders 'Medikament hinzufügen' under Locale('de')", (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('Medikament hinzufügen'), findsOneWidget);
    });

    testWidgets("renders 'Додати ліки' under Locale('uk')", (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      expect(find.text('Додати ліки'), findsOneWidget);
    });
  });

  group('AddMedicationModal structure', () {
    testWidgets('renders one Text title in the AppBar', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Add medication'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AppBar has a back-arrow IconButton leading', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.icon, isA<Icon>());
      final icon = iconButton.icon as Icon;
      expect(icon.icon, LucideIcons.arrowLeft);
    });

    testWidgets('body contains a TextField with the localized name label', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.labelText, 'Medication name');
    });

    testWidgets('body contains a FilledButton with Save label and save icon', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);

      // Verify the icon inside the FilledButton is LucideIcons.save.
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.icon, LucideIcons.save);
    });

    testWidgets('tapping Save does not throw and does not pop the modal', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // The modal must still be in the tree — Save is a no-op in iteration 1.
      expect(find.byType(AddMedicationModal), findsOneWidget);
    });
  });

  group('AddMedicationModal typography', () {
    testWidgets('title Text inherits theme (no explicit style override)', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // The title Text widget inside the AppBar must have no explicit style
      // set — styling flows from the AppBar theme.
      final titleText = tester.widget<Text>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Add medication'),
        ),
      );
      expect(titleText.style, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AC-13: Medication-form picker (spec 027-med-form-picker)
  // ---------------------------------------------------------------------------
  group('AddMedicationModal form picker', () {
    // (a) Collapsed initial state — label and placeholder visible, grid absent.
    testWidgets(
      'shows label and placeholder before any selection; grid is absent',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Display-row label is always present.
        expect(find.text('Medication form'), findsOneWidget);
        // Placeholder text shown when nothing is selected.
        expect(find.text('Choose a form'), findsOneWidget);

        // Grid is conditionally built — absent until the row is tapped.
        expect(find.text('COMMON FORMS'), findsNothing);
        expect(find.text('Tablet'), findsNothing);
        expect(find.text('Syrup'), findsNothing);
      },
    );

    // (b) Tapping the display row expands the grid with title + 8 options.
    testWidgets(
      'tapping display row expands grid with title and all 8 option names',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Tap the chevron icon (stable target inside the InkWell).
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();

        // Grid title is rendered uppercased by the widget.
        expect(find.text('COMMON FORMS'), findsOneWidget);

        // All 8 option names must be present.
        expect(find.text('Tablet'), findsOneWidget);
        expect(find.text('Capsule'), findsOneWidget);
        expect(find.text('Syrup'), findsOneWidget);
        expect(find.text('Drops'), findsOneWidget);
        expect(find.text('Injection'), findsOneWidget);
        expect(find.text('Inhaler'), findsOneWidget);
        expect(find.text('Cream / Ointment'), findsOneWidget);
        expect(find.text('Sachet'), findsOneWidget);
      },
    );

    // (c) Selecting an option updates the display row and collapses the grid.
    testWidgets(
      'selecting Syrup updates display row to Syrup / sub and collapses grid',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Open the grid.
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();

        // Tap the Syrup chip.
        await tester.tap(find.text('Syrup'));
        await tester.pumpAndSettle();

        // Grid must be collapsed again.
        expect(find.text('COMMON FORMS'), findsNothing);
        // Placeholder is gone now that a selection has been made.
        expect(find.text('Choose a form'), findsNothing);

        // Display row now shows the selected option name and sub-description.
        // Only one instance of "Syrup" exists — the grid chip is gone.
        expect(find.text('Syrup'), findsOneWidget);
        expect(find.text('Liquid dosage form'), findsOneWidget);
      },
    );

    // (d) Selecting a second option replaces the first (single-selection).
    testWidgets(
      'selecting Injection after Syrup replaces the selection; Syrup sub gone',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // First selection: Syrup.
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Syrup'));
        await tester.pumpAndSettle();

        // Re-open using the chevron (display row now shows "Syrup" as name;
        // the InputDecorator label floats and may not be hittable — use icon).
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();

        // Second selection: Injection.
        await tester.tap(find.text('Injection'));
        await tester.pumpAndSettle();

        // Grid collapsed — only display-row content remains in the tree.
        expect(find.text('COMMON FORMS'), findsNothing);

        // Display row reflects the latest selection.
        expect(find.text('Injection'), findsOneWidget);
        expect(find.text('Intramuscular / IV'), findsOneWidget);

        // Previous selection's sub-description is gone.
        expect(find.text('Liquid dosage form'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // AC-14: Form-dependent fields (spec 028-form-dependent-fields)
  // ---------------------------------------------------------------------------
  group('AddMedicationModal form-dependent fields', () {
    // (a) No selection — only the name TextField is in the tree.
    testWidgets(
      'no selection shows only name field; stepper, dose and stock absent',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('medsAddQtyValue')), findsNothing);
        expect(find.byKey(const ValueKey('medsAddDoseField')), findsNothing);
        expect(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          findsNothing,
        );
        // Only the medication-name TextField is present before any selection.
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    // (b) Tablet → stepper + stock visible; dose field absent.
    testWidgets(
      'Tablet shows quantity stepper and stock card; dose field absent',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        // Stepper value present and initialised to the tablet minimum (0.5).
        expect(find.byKey(const ValueKey('medsAddQtyValue')), findsOneWidget);
        final qtyText = tester.widget<Text>(
          find.byKey(const ValueKey('medsAddQtyValue')),
        );
        expect(qtyText.data, '0.5');

        // Stepper label and unit are rendered.
        expect(find.text('Quantity per intake'), findsOneWidget);
        expect(find.text('tab'), findsOneWidget);

        // Stock card fields are present.
        expect(find.text('Remaining'), findsOneWidget);
        expect(find.text('Total in pack'), findsOneWidget);
        expect(find.text('Warn when remaining reaches'), findsOneWidget);

        // Dose field is absent for tablet.
        expect(find.byKey(const ValueKey('medsAddDoseField')), findsNothing);
      },
    );

    // (c) Stepper math — increment, decrement, clamp; then switch to Capsule.
    testWidgets(
      'stepper increments and decrements correctly and clamps at minimum',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Select Tablet (min 0.5, step 0.5).
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        final qtyFinder = find.byKey(const ValueKey('medsAddQtyValue'));
        final incrementFinder = find.byKey(
          const ValueKey('medsAddQtyIncrement'),
        );
        final decrementFinder = find.byKey(
          const ValueKey('medsAddQtyDecrement'),
        );

        // Initial value is 0.5.
        expect(tester.widget<Text>(qtyFinder).data, '0.5');

        // Increment once → 1.
        await tester.tap(incrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '1');

        // Increment again → 1.5.
        await tester.tap(incrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '1.5');

        // Decrement → 1.
        await tester.tap(decrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '1');

        // Decrement → 0.5 (the minimum).
        await tester.tap(decrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '0.5');

        // Decrement again — must clamp at 0.5.
        await tester.tap(decrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '0.5');

        // Switch to Capsule (min 1, step 1) — resets quantity.
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Capsule'));
        await tester.pumpAndSettle();

        // Capsule initial value is 1.
        expect(tester.widget<Text>(qtyFinder).data, '1');

        // Increment → 2.
        await tester.tap(incrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '2');

        // Decrement → 1.
        await tester.tap(decrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '1');

        // Decrement again — must clamp at 1.
        await tester.tap(decrementFinder);
        await tester.pump();
        expect(tester.widget<Text>(qtyFinder).data, '1');
      },
    );

    // (d) Syrup → dose field + unit dropdown; stepper and stock absent.
    testWidgets(
      'Syrup shows dose field with ml unit; stepper and stock absent',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Syrup'));
        await tester.pumpAndSettle();

        // Dose amount field is present.
        expect(find.byKey(const ValueKey('medsAddDoseField')), findsOneWidget);

        // Dose unit dropdown is present and shows ml as the selected value.
        expect(find.byKey(const ValueKey('medsAddDoseUnit')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddDoseUnit')),
            matching: find.text('ml'),
          ),
          findsOneWidget,
        );

        // Stepper and stock are absent for Syrup.
        expect(find.byKey(const ValueKey('medsAddQtyValue')), findsNothing);
        expect(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          findsNothing,
        );
      },
    );

    // (e) Inhaler → no conditional fields at all.
    testWidgets('Inhaler shows no conditional fields', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inhaler'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('medsAddQtyValue')), findsNothing);
      expect(find.byKey(const ValueKey('medsAddDoseField')), findsNothing);
      expect(find.byKey(const ValueKey('medsAddStockRemaining')), findsNothing);
    });

    // (f) Reset on switch — Tablet then Syrup clears stepper and stock.
    testWidgets(
      'switching from Tablet to Syrup removes stepper and stock; shows dose',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Select Tablet — stepper and stock appear.
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('medsAddQtyValue')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          findsOneWidget,
        );

        // Switch to Syrup.
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Syrup'));
        await tester.pumpAndSettle();

        // Stepper and stock are gone; dose field is present.
        expect(find.byKey(const ValueKey('medsAddQtyValue')), findsNothing);
        expect(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('medsAddDoseField')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Intake-time chips (spec 029-intake-time-chips)
  // ---------------------------------------------------------------------------
  group('AddMedicationModal intake time', () {
    // (1) Initial empty state — section title + add chip present; no InputChips.
    testWidgets(
      'shows section title and add chip; no InputChips on first open',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Section title (medsAddTimeTitle).
        expect(find.text('Intake time'), findsOneWidget);
        // Trailing add ActionChip (medsAddTimeAddChip).
        expect(find.widgetWithText(ActionChip, 'Time'), findsOneWidget);
        // No time chips yet.
        expect(find.byType(InputChip), findsNothing);
      },
    );

    // (2) Add a time — one InputChip with the 24-hour label appears.
    testWidgets(
      'tapping add chip, entering 09:00, and confirming adds one InputChip',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Open the time picker via the add chip.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();

        // Enter 09:00 in text-input mode and confirm.
        await _pickTimeInDialog(tester, hour: '09', minute: '00');

        // Exactly one InputChip with the 24-hour label.
        expect(find.byType(InputChip), findsOneWidget);
        expect(find.text('09:00'), findsOneWidget);
      },
    );

    // (3) Cancel adds nothing — InputChip count stays at zero.
    testWidgets('cancelling the time picker does not add any InputChip', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Open the time picker via the add chip.
      await tester.tap(find.widgetWithText(ActionChip, 'Time'));
      await tester.pumpAndSettle();

      // Tap Cancel instead of OK.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsNothing);
    });

    // (4) Edit replaces — tapping a chip body opens the picker; new time replaces old.
    testWidgets(
      'tapping chip body, entering 10:30, replaces 09:00 with 10:30',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Add 09:00 first.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '09', minute: '00');

        // Tap the chip BODY (onPressed — not the delete icon).
        await tester.tap(find.byType(InputChip));
        await tester.pumpAndSettle();

        // Edit to 10:30.
        await _pickTimeInDialog(tester, hour: '10', minute: '30');

        // 09:00 is gone; 10:30 is present; exactly one chip.
        expect(find.text('10:30'), findsOneWidget);
        expect(find.text('09:00'), findsNothing);
        expect(find.byType(InputChip), findsOneWidget);
      },
    );

    // (5) Delete via × — chip is removed; no time-picker dialog opens.
    testWidgets(
      'tapping the delete icon removes the chip without opening a picker',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Add 09:00.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '09', minute: '00');

        // Tap the × delete icon on the chip.
        await tester.tap(find.byIcon(LucideIcons.x));
        await tester.pumpAndSettle();

        // Chip is gone.
        expect(find.byType(InputChip), findsNothing);
        // No time-picker dialog is open (its OK button is absent).
        expect(find.text('OK'), findsNothing);
      },
    );

    // (6) Ascending order — chips are sorted regardless of insertion order.
    testWidgets('adding 20:00 then 08:00 renders 08:00 before 20:00', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Add 20:00 first.
      await tester.tap(find.widgetWithText(ActionChip, 'Time'));
      await tester.pumpAndSettle();
      await _pickTimeInDialog(tester, hour: '20', minute: '00');

      // Add 08:00 second.
      await tester.tap(find.widgetWithText(ActionChip, 'Time'));
      await tester.pumpAndSettle();
      await _pickTimeInDialog(tester, hour: '08', minute: '00');

      // Both chips exist.
      expect(find.byType(InputChip), findsNWidgets(2));

      // 08:00 must appear before 20:00 in the widget tree (ascending order).
      // Compare the vertical position: the chip with the earlier time must
      // have a smaller or equal dy than the later chip.  Since both chips
      // are in a Wrap they may share a row (same dy) — in that case compare
      // the horizontal position (dx).
      final earlyOffset = tester.getTopLeft(find.text('08:00'));
      final lateOffset = tester.getTopLeft(find.text('20:00'));

      // A chip that appears first in the Wrap is either on a higher row
      // (smaller dy) or is to the left on the same row (smaller dx).
      final isEarlierInLayout =
          earlyOffset.dy < lateOffset.dy ||
          (earlyOffset.dy == lateOffset.dy && earlyOffset.dx < lateOffset.dx);
      expect(isEarlierInLayout, isTrue);
    });

    // (7) Duplicate rejected — SnackBar shown; chip count stays at one.
    testWidgets(
      'adding the same time twice shows duplicate SnackBar and keeps one chip',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Add 08:00 the first time.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '08', minute: '00');

        // Attempt to add 08:00 a second time.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '08', minute: '00');

        // Still exactly one chip.
        expect(find.byType(InputChip), findsOneWidget);
        expect(find.text('08:00'), findsOneWidget);

        // SnackBar with the duplicate message is visible.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('This time is already added'), findsOneWidget);
      },
    );

    // (8) AC-9 second half — editing a chip to its own current value is a
    //     silent no-op: the chip is preserved and no duplicate SnackBar appears.
    testWidgets(
      'editing a chip to its own current value is a silent no-op (no SnackBar)',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        // Add 08:00.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '08', minute: '00');

        // Tap the chip BODY (onPressed — not the delete icon) to open the editor.
        await tester.tap(find.byType(InputChip));
        await tester.pumpAndSettle();

        // Confirm the picker with the same value 08:00.
        await _pickTimeInDialog(tester, hour: '08', minute: '00');

        // The chip must still be present — the edit must not drop it.
        expect(find.byType(InputChip), findsOneWidget);
        expect(find.text('08:00'), findsOneWidget);

        // No duplicate SnackBar must appear for an edit-to-own-value.
        expect(find.text('This time is already added'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Section dividers and section-title styling (spec 031)
  // ---------------------------------------------------------------------------
  group('AddMedicationModal dividers', () {
    // (1) Two Dividers present unconditionally on a freshly pumped modal.
    testWidgets('renders exactly two Dividers with no form selected', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsNWidgets(2));
    });

    // (2) The first Divider has thickness 1 and color == outlineVariant.
    testWidgets(
      'first Divider has thickness 1 and color matching outlineVariant',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final colorScheme = Theme.of(
          tester.element(find.byType(AddMedicationModal)),
        ).colorScheme;

        final divider = tester.widget<Divider>(find.byType(Divider).first);
        expect(divider.thickness, 1);
        expect(divider.color, colorScheme.outlineVariant);
      },
    );

    // (3) Both section-title Text widgets use color == onSurfaceVariant.
    testWidgets(
      'section titles use onSurfaceVariant color',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final colorScheme = Theme.of(
          tester.element(find.byType(AddMedicationModal)),
        ).colorScheme;

        final intakeTimeTitle = tester.widget<Text>(find.text('Intake time'));
        expect(intakeTimeTitle.style?.color, colorScheme.onSurfaceVariant);

        final intakeTypeTitle = tester.widget<Text>(find.text('Intake type'));
        expect(intakeTypeTitle.style?.color, colorScheme.onSurfaceVariant);
      },
    );

    // (4) AC-1 — two Dividers remain when a form (Tablet) is selected.
    testWidgets(
      'renders exactly two Dividers with Tablet form selected',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        expect(find.byType(Divider), findsNWidgets(2));
      },
    );

    // (5) AC-1 — two Dividers remain when Course intake type is selected.
    testWidgets(
      'renders exactly two Dividers with Course intake type selected',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Course'));
        await tester.pumpAndSettle();

        expect(find.byType(Divider), findsNWidgets(2));
      },
    );

    // (6) AC-3 — the second Divider also has thickness 1 and color == outlineVariant.
    testWidgets(
      'second Divider has thickness 1 and color matching outlineVariant',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final colorScheme = Theme.of(
          tester.element(find.byType(AddMedicationModal)),
        ).colorScheme;

        final divider = tester.widget<Divider>(find.byType(Divider).last);
        expect(divider.thickness, 1);
        expect(divider.color, colorScheme.outlineVariant);
      },
    );

    // (7) AC-6 — _StockCard header ('Pack stock') is NOT muted with onSurfaceVariant.
    testWidgets(
      'Pack stock header uses titleSmall and is not muted with onSurfaceVariant',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(AddMedicationModal));
        final textTheme = Theme.of(element).textTheme;
        final colorScheme = Theme.of(element).colorScheme;

        final stockHeader = tester.widget<Text>(find.text('Pack stock'));
        expect(stockHeader.style, textTheme.titleSmall);
        expect(stockHeader.style?.color, isNot(colorScheme.onSurfaceVariant));
      },
    );

    // (8) AC-6 — _CourseCard header ('Course parameters') is NOT muted with onSurfaceVariant.
    testWidgets(
      'Course parameters header uses titleSmall and is not muted with onSurfaceVariant',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Course'));
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(AddMedicationModal));
        final textTheme = Theme.of(element).textTheme;
        final colorScheme = Theme.of(element).colorScheme;

        final courseHeader = tester.widget<Text>(find.text('Course parameters'));
        expect(courseHeader.style, textTheme.titleSmall);
        expect(courseHeader.style?.color, isNot(colorScheme.onSurfaceVariant));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Intake-type section (spec 030-intake-type)
  // ---------------------------------------------------------------------------

  /// Fixed test clock: 26 March 2026.
  ///
  /// All tests that depend on the default start date (today) must wrap
  /// [pumpWidget] in [withClock] using this constant so results are
  /// deterministic regardless of when the suite runs.
  final fixedClock = Clock.fixed(DateTime(2026, 3, 26));

  /// Selects the "Course" segment inside the [SegmentedButton] (en locale).
  ///
  /// Taps the visible "Course" text label.  After this call the caller must
  /// invoke [WidgetTester.pumpAndSettle] to allow the state update to render
  /// the CourseCard.
  Future<void> selectCourse(WidgetTester tester) async {
    await tester.tap(find.text('Course'));
    await tester.pumpAndSettle();
  }

  group('AddMedicationModal intake type', () {
    // -------------------------------------------------------------------------
    // AC-3: SegmentedButton present; CourseCard absent by default.
    // -------------------------------------------------------------------------
    testWidgets(
      'segmented button is present and course card is absent on open (AC-3)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
        });

        // The segmented button is always visible.
        expect(
          find.byKey(const ValueKey('medsAddIntakeTypeSegmented')),
          findsOneWidget,
        );

        // The course card (and all its children) must be absent — default is
        // Continuous.
        expect(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('medsAddCourseInfoChip')),
          findsNothing,
        );
      },
    );

    // -------------------------------------------------------------------------
    // AC-2 / AC-4 / AC-6: selecting Course shows the card with defaults.
    // -------------------------------------------------------------------------
    testWidgets(
      'selecting Course shows course card with default duration 7 and pause 0 (AC-2/AC-4/AC-6)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);
        });

        // Course card appears.
        expect(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('medsAddCoursePause')),
          findsOneWidget,
        );

        // Duration field pre-filled with "7".
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseDuration')),
            matching: find.text('7'),
          ),
          findsOneWidget,
        );

        // Pause field pre-filled with "0".
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCoursePause')),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
      },
    );

    // -------------------------------------------------------------------------
    // AC-5: switching back to Continuous hides the course card.
    // -------------------------------------------------------------------------
    testWidgets(
      'switching back to Continuous removes the course card (AC-5)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();

          // First select Course — card appears.
          await selectCourse(tester);
          expect(
            find.byKey(const ValueKey('medsAddCourseDuration')),
            findsOneWidget,
          );

          // Switch back to Continuous.
          await tester.tap(find.text('Continuous'));
          await tester.pumpAndSettle();
        });

        // Course card must be gone.
        expect(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          findsNothing,
        );
      },
    );

    // -------------------------------------------------------------------------
    // AC-7: start-date field shows today formatted with MaterialLocalizations.
    // -------------------------------------------------------------------------
    testWidgets(
      'start-date field shows today in en medium format after selecting Course (AC-7)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);
        });

        // The start-date InkWell must be present.
        expect(
          find.byKey(const ValueKey('medsAddCourseStartField')),
          findsOneWidget,
        );

        // The displayed date for 2026-03-26 in en medium format is "Thu, Mar 26"
        // (MaterialLocalizations.formatMediumDate includes the day-of-week
        // abbreviation but omits the year).
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseStartField')),
            matching: find.text('Thu, Mar 26'),
          ),
          findsOneWidget,
        );
      },
    );

    // -------------------------------------------------------------------------
    // AC-9: info chip shows inclusive date range with default duration 7.
    // -------------------------------------------------------------------------
    testWidgets(
      'info chip shows correct 7-day range (Thu Mar 26 – Wed Apr 1) by default (AC-9)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);
        });

        // The info chip must be present.
        expect(
          find.byKey(const ValueKey('medsAddCourseInfoChip')),
          findsOneWidget,
        );

        // end = 2026-03-26 + (7-1) days = 2026-04-01 → "Wed, Apr 1".
        // The label format is: Course: {start} — {end} ({count} days).
        final infoText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseInfoChip')),
            matching: find.byType(Text),
          ),
        );
        expect(infoText.data, contains('Wed, Apr 1'));
        expect(infoText.data, contains('7 days'));
      },
    );

    // -------------------------------------------------------------------------
    // AC-9 live update: changing duration updates the info chip immediately.
    // -------------------------------------------------------------------------
    testWidgets(
      'changing duration to 3 updates info chip to Sat Mar 28 and 3 days (AC-9 live)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);

          // Enter "3" into the duration field.
          await tester.enterText(
            find.byKey(const ValueKey('medsAddCourseDuration')),
            '3',
          );
          await tester.pumpAndSettle();

          // end = 2026-03-26 + (3-1) days = 2026-03-28 → "Sat, Mar 28".
          final infoText = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('medsAddCourseInfoChip')),
              matching: find.byType(Text),
            ),
          );
          expect(infoText.data, contains('Sat, Mar 28'));
          expect(infoText.data, contains('3 days'));
        });
      },
    );

    // -------------------------------------------------------------------------
    // AC-10: invalid / empty duration falls back to start-only label.
    // -------------------------------------------------------------------------
    testWidgets(
      'clearing duration shows start-only fallback label (AC-10)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);

          // Clear the duration field.
          await tester.enterText(
            find.byKey(const ValueKey('medsAddCourseDuration')),
            '',
          );
          await tester.pumpAndSettle();

          // Fallback: "Course starts Thu, Mar 26" — no "days" substring.
          final infoText = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('medsAddCourseInfoChip')),
              matching: find.byType(Text),
            ),
          );
          expect(infoText.data, contains('Course starts'));
          expect(infoText.data, contains('Thu, Mar 26'));
          expect(infoText.data, isNot(contains('days')));
        });
      },
    );

    testWidgets(
      'non-numeric duration shows start-only fallback label without throwing (AC-10)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);

          // Enter non-numeric text.
          await tester.enterText(
            find.byKey(const ValueKey('medsAddCourseDuration')),
            'abc',
          );
          await tester.pumpAndSettle();

          // Fallback shown; no "days" range.
          final infoText = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('medsAddCourseInfoChip')),
              matching: find.byType(Text),
            ),
          );
          expect(infoText.data, contains('Course starts'));
          expect(infoText.data, isNot(contains('days')));
        });
      },
    );

    // -------------------------------------------------------------------------
    // AC-8: tapping start-date field opens the date picker.
    //       Cancel: start date and info chip unchanged.
    //       Confirm: selecting a different day updates the field and info chip.
    // -------------------------------------------------------------------------
    testWidgets(
      'tapping Cancel in date picker leaves start date and info chip unchanged (AC-8)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);
        });

        // Tap the start-date field to open the date picker.
        await tester.tap(find.byKey(const ValueKey('medsAddCourseStartField')));
        await tester.pumpAndSettle();

        // A DatePickerDialog must now be in the tree.
        expect(find.byType(DatePickerDialog), findsOneWidget);

        // Tap Cancel — dialog dismisses without changing the date.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog is gone.
        expect(find.byType(DatePickerDialog), findsNothing);

        // Start-date field still shows the original date.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseStartField')),
            matching: find.text('Thu, Mar 26'),
          ),
          findsOneWidget,
        );

        // Info chip still shows the original 7-day range.
        final infoText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseInfoChip')),
            matching: find.byType(Text),
          ),
        );
        expect(infoText.data, contains('Thu, Mar 26'));
        expect(infoText.data, contains('7 days'));
      },
    );

    testWidgets(
      'confirming a new date in the date picker updates start field and info chip (AC-8)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('en')));
          await tester.pumpAndSettle();
          await selectCourse(tester);
        });

        // Tap the start-date field to open the date picker.
        await tester.tap(find.byKey(const ValueKey('medsAddCourseStartField')));
        await tester.pumpAndSettle();

        // A DatePickerDialog must now be in the tree.
        expect(find.byType(DatePickerDialog), findsOneWidget);

        // The picker opens in calendar mode for March 2026.
        // Tap day "15" scoped to the dialog to avoid matching text elsewhere.
        // Result: March 15, 2026 (formatMediumDate → "Sun, Mar 15").
        await tester.tap(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('15'),
          ),
        );
        await tester.pumpAndSettle();

        // Confirm with OK.
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Dialog is dismissed.
        expect(find.byType(DatePickerDialog), findsNothing);

        // Start-date field now shows "Sun, Mar 15".
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseStartField')),
            matching: find.text('Sun, Mar 15'),
          ),
          findsOneWidget,
        );

        // Info chip: end = Mar 15 + (7-1) days = Mar 21 → "Sat, Mar 21".
        final infoText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseInfoChip')),
            matching: find.byType(Text),
          ),
        );
        expect(infoText.data, contains('Sun, Mar 15'));
        expect(infoText.data, contains('Sat, Mar 21'));
        expect(infoText.data, contains('7 days'));
      },
    );

    // -------------------------------------------------------------------------
    // AC-11: Ukrainian plural forms for 1, 2, and 5 days.
    // -------------------------------------------------------------------------
    testWidgets(
      'uk plural: duration 1 → день, 2 → дні, 5 → днів (AC-11)',
      (tester) async {
        await withClock(fixedClock, () async {
          await tester.pumpWidget(_harness(locale: const Locale('uk')));
          await tester.pumpAndSettle();
          // Select Course via the uk label "Курс".
          await tester.tap(find.text('Курс'));
          await tester.pumpAndSettle();
        });

        // Helper that reads the info chip text.
        Text infoChipText() => tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseInfoChip')),
            matching: find.byType(Text),
          ),
        );

        // Duration 1 → "1 день".
        await tester.enterText(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          '1',
        );
        await tester.pumpAndSettle();
        expect(infoChipText().data, contains('день'));

        // Duration 2 → "2 дні".
        await tester.enterText(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          '2',
        );
        await tester.pumpAndSettle();
        expect(infoChipText().data, contains('дні'));

        // Duration 5 → "5 днів".
        await tester.enterText(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          '5',
        );
        await tester.pumpAndSettle();
        expect(infoChipText().data, contains('днів'));
      },
    );
  });
}
