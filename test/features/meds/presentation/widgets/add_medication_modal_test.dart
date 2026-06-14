// Tests for the AddMedicationModal.
// spec 011-meds-add-fab    — AppBar back-arrow / title / typography.
// spec 026-add-med-name-input — body TextField and Save button structure.
// spec 027-med-form-picker — medication-form picker (collapse/expand/select).
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

    testWidgets(
      'body contains a FilledButton with Save label and save icon',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(FilledButton, 'Save'),
          findsOneWidget,
        );

        // Verify the icon inside the FilledButton is LucideIcons.save.
        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(FilledButton),
            matching: find.byType(Icon),
          ),
        );
        expect(icon.icon, LucideIcons.save);
      },
    );

    testWidgets(
      'tapping Save does not throw and does not pop the modal',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // The modal must still be in the tree — Save is a no-op in iteration 1.
        expect(find.byType(AddMedicationModal), findsOneWidget);
      },
    );
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

        expect(
          find.byKey(const ValueKey('medsAddQtyValue')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('medsAddDoseField')),
          findsNothing,
        );
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
        expect(
          find.byKey(const ValueKey('medsAddQtyValue')),
          findsOneWidget,
        );
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
        expect(
          find.byKey(const ValueKey('medsAddDoseField')),
          findsNothing,
        );
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
        final incrementFinder =
            find.byKey(const ValueKey('medsAddQtyIncrement'));
        final decrementFinder =
            find.byKey(const ValueKey('medsAddQtyDecrement'));

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
        expect(
          find.byKey(const ValueKey('medsAddDoseField')),
          findsOneWidget,
        );

        // Dose unit dropdown is present and shows ml as the selected value.
        expect(
          find.byKey(const ValueKey('medsAddDoseUnit')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddDoseUnit')),
            matching: find.text('ml'),
          ),
          findsOneWidget,
        );

        // Stepper and stock are absent for Syrup.
        expect(
          find.byKey(const ValueKey('medsAddQtyValue')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          findsNothing,
        );
      },
    );

    // (e) Inhaler → no conditional fields at all.
    testWidgets(
      'Inhaler shows no conditional fields',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inhaler'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('medsAddQtyValue')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('medsAddDoseField')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          findsNothing,
        );
      },
    );

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

        expect(
          find.byKey(const ValueKey('medsAddQtyValue')),
          findsOneWidget,
        );
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
        expect(
          find.byKey(const ValueKey('medsAddQtyValue')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('medsAddDoseField')),
          findsOneWidget,
        );
      },
    );
  });
}
