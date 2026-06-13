// Tests for the AddMedicationModal. The body field/Save-button tests enforce
// spec 026-add-med-name-input; the AppBar back-arrow/title/typography tests carry over from spec 011-meds-add-fab.
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
}
