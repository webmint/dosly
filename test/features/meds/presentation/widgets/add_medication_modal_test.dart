// Tests for the AddMedicationModal.
// spec 011-meds-add-fab    — AppBar back-arrow / title / typography.
// spec 026-add-med-name-input — body TextField and Save button structure.
// spec 027-med-form-picker — medication-form picker (collapse/expand/select).
// spec 028-form-dependent-fields — dose/quantity/stock conditional fields.
// spec 029-intake-time-chips — intake-time chips (add/edit/remove/sort/duplicate).
// spec 030-intake-type — intake-type segmented button and course-parameters card.
// spec 032-med-persistence — wired Save: valid input persists + pops; invalid
//                            shows localized error SnackBar and stays open.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/id/id_generator.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/pack_stock.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/repositories/medication_repository.dart';
import 'package:dosly/features/meds/domain/usecases/add_medication.dart';
import 'package:dosly/features/meds/domain/usecases/delete_medication.dart';
import 'package:dosly/features/meds/domain/usecases/edit_medication.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/providers/medication_providers.dart';
import 'package:dosly/features/meds/presentation/widgets/add_medication_modal.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ---------------------------------------------------------------------------
// Fakes for persistence tests (spec 032)
// ---------------------------------------------------------------------------

/// A fake [MedicationRepository] that returns [Right] for every [add] call.
///
/// Inject this into [AddMedication] inside [addMedicationProvider.overrideWith]
/// so no real drift database is touched during widget tests.
class _FakeMedicationRepository implements MedicationRepository {
  /// If non-null, the next [add] call will complete this instead of returning
  /// immediately.  Used to test the "button disabled while saving" scenario.
  Completer<Either<Failure, Medication>>? completer;

  @override
  Future<Either<Failure, Medication>> add(Medication medication) {
    if (completer != null) {
      return completer!.future;
    }
    return Future.value(Right(medication));
  }

  @override
  Future<Either<Failure, Medication>> update(Medication medication) {
    if (completer != null) {
      return completer!.future;
    }
    return Future.value(Right(medication));
  }

  @override
  Stream<Either<Failure, List<Medication>>> watchAll() =>
      const Stream<Either<Failure, List<Medication>>>.empty();

  @override
  Future<Either<Failure, void>> delete(MedicationId id) async =>
      const Right(null);
}

/// A recording [MedicationRepository] that captures the last [Medication]
/// passed to [add] (and, separately, to [update]) and always returns [Right].
///
/// Used by the Gap-1 and Gap-2 widget tests so assertions can inspect the
/// exact [Medication] the modal built — proving correct field mapping without
/// hitting any real drift database.
class _RecordingMedicationRepository implements MedicationRepository {
  /// The [Medication] from the most recent [add] call, or `null` if [add] has
  /// not been called yet.
  Medication? captured;

  /// The [Medication] from the most recent [update] call, or `null` if [update]
  /// has not been called yet.
  Medication? capturedUpdate;

  /// The [MedicationId] from the most recent [delete] call, or `null` if
  /// [delete] has not been called yet.
  ///
  /// Used by the delete widget tests (spec 037) to assert the trash action
  /// forwards the *original* medication's id, not a stale/edited one.
  MedicationId? capturedDeleteId;

  /// Number of times [delete] has been invoked — used to assert "called
  /// exactly once" and "never called" (Cancel no-op) expectations.
  int deleteCallCount = 0;

  /// The value [delete] resolves to. Defaults to a successful no-op; tests
  /// override this to `Left(...)` to exercise the failure SnackBar path.
  Either<Failure, void> deleteResult = const Right(null);

  /// If non-null, the next [delete] call returns this completer's future
  /// instead of resolving immediately. Used by the in-flight guard test
  /// (spec 037 AC-12) to keep a delete pending so the trash button's
  /// disabled state can be asserted mid-flight — mirrors
  /// [_FakeMedicationRepository.completer]'s technique for save.
  Completer<Either<Failure, void>>? deleteCompleter;

  @override
  Future<Either<Failure, Medication>> add(Medication medication) async {
    captured = medication;
    return Right(medication);
  }

  @override
  Future<Either<Failure, Medication>> update(Medication medication) async {
    capturedUpdate = medication;
    return Right(medication);
  }

  @override
  Stream<Either<Failure, List<Medication>>> watchAll() =>
      const Stream<Either<Failure, List<Medication>>>.empty();

  @override
  Future<Either<Failure, void>> delete(MedicationId id) async {
    capturedDeleteId = id;
    deleteCallCount++;
    if (deleteCompleter != null) {
      return deleteCompleter!.future;
    }
    return deleteResult;
  }
}

/// A fake [IdGenerator] that returns deterministic sequential IDs.
class _FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String newId() => 'test-id-${++_counter}';
}

/// Builds a test [Medication] value for assertions in the success path.
///
/// The exact entity is not checked field-by-field in the widget test — we only
/// need the Right branch to exist and carry a [Medication] so the modal pops.
Medication _fakeMinimalMedication() => Medication(
  id: const MedicationId('test-id-1'),
  name: 'Test Med',
  form: MedicationForm.inhaler,
  type: MedicationType.continuous(
    startDate: DateTime.utc(2026, 3, 26),
  ),
  schedule: const Schedule(slots: []),
  createdAt: DateTime.utc(2026, 3, 26),
);

// ---------------------------------------------------------------------------
// Test harnesses
// ---------------------------------------------------------------------------

/// Builds a [MaterialApp] that renders [AddMedicationModal] **directly as
/// [home]** (no ProviderScope).  Used by the non-persistence tests (specs
/// 026–031) to keep those tests unchanged and dependency-free.
Widget _harness({required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: resolveAppLocale,
    home: const AddMedicationModal(),
  );
}

/// Builds a localized [ProviderScope] + [MaterialApp] where the modal is
/// pushed **on top of a base route** so that [Navigator.pop] is observable.
///
/// Strategy: the [home] is a plain [Scaffold] with a button; tapping the
/// button pushes [AddMedicationModal] via [Navigator.push].  After the push
/// only the modal is visible.  After a successful save the modal pops and the
/// base scaffold is visible again, which lets us assert the modal is gone.
///
/// [overrides] receives the [addMedicationProvider] override so no real drift
/// DB is ever touched.
Widget _persistenceHarness({
  required Locale locale,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            key: const ValueKey('openModal'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => const AddMedicationModal(),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

/// Opens the modal by tapping the launcher button in [_persistenceHarness].
Future<void> _openModal(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('openModal')));
  await tester.pumpAndSettle();
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
  });

  // ---------------------------------------------------------------------------
  // Save behavior — wired persistence (spec 032)
  //
  // These tests use _persistenceHarness which pushes the modal on top of a
  // base route, making Navigator.pop observable.  addMedicationProvider is
  // overridden with a fake repo (no real drift DB touched).
  // ---------------------------------------------------------------------------
  group('AddMedicationModal Save — wired behavior (spec 032)', () {
    // -------------------------------------------------------------------------
    // Helper: build an override that wires AddMedication to a given fake repo.
    // -------------------------------------------------------------------------
    List<Override> buildOverrides(_FakeMedicationRepository repo) => [
      addMedicationProvider.overrideWith((_) => AddMedication(repo, _FakeIdGenerator())),
    ];

    // -------------------------------------------------------------------------
    // (1) Valid input → success SnackBar + route popped.
    //
    // Uses Inhaler (no dose/stock fields, no extra conditional widgets) so the
    // test only needs name + one time to satisfy all validation rules.
    // -------------------------------------------------------------------------
    testWidgets(
      'valid input: success SnackBar appears and modal is popped (spec 032)',
      (tester) async {
        final repo = _FakeMedicationRepository();

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: buildOverrides(repo),
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Modal must be visible.
        expect(find.byType(AddMedicationModal), findsOneWidget);

        // Fill in a medication name.
        await tester.enterText(find.byType(TextField).first, 'Aspirin');
        await tester.pumpAndSettle();

        // Select Inhaler (no dose/stock/quantity extra fields).
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inhaler'));
        await tester.pumpAndSettle();

        // Add one intake time (09:00) to satisfy the times-required validation.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '09', minute: '00');

        // Tap Save.
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Success SnackBar must appear.
        expect(find.text('Medication saved'), findsOneWidget);

        // Modal must be gone — base route is visible instead.
        expect(find.byType(AddMedicationModal), findsNothing);
        expect(find.byKey(const ValueKey('openModal')), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // (2) Invalid input (empty name) → medsAddSaveErrorName SnackBar, no pop.
    //
    // Uses Inhaler + one intake time so the only failing rule is the empty name.
    // -------------------------------------------------------------------------
    testWidgets(
      'empty name: medsAddSaveErrorName SnackBar appears and modal stays open (spec 032)',
      (tester) async {
        final repo = _FakeMedicationRepository();

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: buildOverrides(repo),
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Select Inhaler so form != null (avoids generic null-form SnackBar).
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inhaler'));
        await tester.pumpAndSettle();

        // Add one intake time to avoid the times-required error.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '09', minute: '00');

        // Leave name empty — do NOT enter any text.

        // Tap Save.
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // The name-validation error SnackBar must appear.
        expect(find.text('Enter a medication name'), findsOneWidget);

        // Modal must still be in the tree — it must NOT have popped.
        expect(find.byType(AddMedicationModal), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // (3) Save button disabled while save is in flight (prevents double-taps).
    //
    // Uses a Completer-backed repo so the save never resolves during the test,
    // allowing us to assert onPressed == null before the completer fires.
    // -------------------------------------------------------------------------
    testWidgets(
      'FilledButton.onPressed is null while save is in flight (spec 032)',
      (tester) async {
        final completer = Completer<Either<Failure, Medication>>();
        final repo = _FakeMedicationRepository()..completer = completer;

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: buildOverrides(repo),
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Fill name + form + time so validation passes.
        await tester.enterText(find.byType(TextField).first, 'Aspirin');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inhaler'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '09', minute: '00');

        // Tap Save — the completer never resolves so the await hangs.
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        // pump() — not pumpAndSettle — so we stay mid-flight.
        await tester.pump();

        // The button must be disabled while in flight.
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);

        // Resolve the completer to clean up pending timers so the test runner
        // doesn't report outstanding async work.
        completer.complete(Right(_fakeMinimalMedication()));
        await tester.pumpAndSettle();
      },
    );

    // -------------------------------------------------------------------------
    // (4) Gap 1 Tablet: success + captured.dosePerIntake.unit == tablet,
    //     form == tablet, stock == null (stock fields left blank).
    // -------------------------------------------------------------------------
    testWidgets(
      'Gap1-Tablet: success SnackBar + pop; captured dose unit is tablet, stock is null (spec 032)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final overrides = [
          addMedicationProvider.overrideWith(
            (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
          ),
        ];

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: overrides,
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Fill medication name.
        await tester.enterText(find.byType(TextField).first, 'Paracetamol');
        await tester.pumpAndSettle();

        // Select Tablet form via the chevron + grid.
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        // Add one intake time (08:00) — uses existing _pickTimeInDialog helper.
        // Tablet adds a stepper + stock card, so the time chip may be off-screen:
        // scroll it into view before tapping.
        await tester.ensureVisible(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '08', minute: '00');

        // Leave all stock fields blank (do NOT touch them).

        // Tap Save — scroll it into view first.
        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Success SnackBar.
        expect(find.text('Medication saved'), findsOneWidget);

        // Modal is popped — base route visible.
        expect(find.byType(AddMedicationModal), findsNothing);
        expect(find.byKey(const ValueKey('openModal')), findsOneWidget);

        // The recording repo must have been called.
        final captured = recordingRepo.captured;
        expect(captured, isNotNull);

        // Dose: quantity stepper defaults to 0.5 tab for Tablet.
        expect(captured!.dosePerIntake, isNotNull);
        expect(captured.dosePerIntake!.unit, DoseUnit.tablet);
        expect(captured.dosePerIntake!.amount, greaterThan(0));

        // Form round-tripped correctly.
        expect(captured.form, MedicationForm.tablet);

        // Stock fields were blank → stock must be null.
        expect(captured.stock, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // (5) Gap 1 Syrup: success + captured.dosePerIntake == Dosage(5, ml),
    //     stock == null.
    // -------------------------------------------------------------------------
    testWidgets(
      'Gap1-Syrup: success SnackBar + pop; captured dose is 5ml, stock is null (spec 032)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final overrides = [
          addMedicationProvider.overrideWith(
            (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
          ),
        ];

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: overrides,
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Fill medication name.
        await tester.enterText(find.byType(TextField).first, 'Amoxicillin Syrup');
        await tester.pumpAndSettle();

        // Select Syrup form.
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Syrup'));
        await tester.pumpAndSettle();

        // Enter "5" into the dose field.
        await tester.enterText(
          find.byKey(const ValueKey('medsAddDoseField')),
          '5',
        );
        await tester.pumpAndSettle();

        // Add one intake time (12:00).
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '12', minute: '00');

        // Tap Save.
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Success.
        expect(find.text('Medication saved'), findsOneWidget);
        expect(find.byType(AddMedicationModal), findsNothing);

        final captured = recordingRepo.captured;
        expect(captured, isNotNull);

        // Dose field value: 5 ml.
        expect(
          captured!.dosePerIntake,
          const Dosage(amount: 5, unit: DoseUnit.ml),
        );

        // Syrup has no stock card → stock must be null.
        expect(captured.stock, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // (6) Gap 1 PackStock partial-input: only remaining filled → stock == null.
    // -------------------------------------------------------------------------
    testWidgets(
      'Gap1-PackStock-partial: only remaining stock field filled → captured.stock is null (spec 032)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final overrides = [
          addMedicationProvider.overrideWith(
            (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
          ),
        ];

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: overrides,
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Fill medication name.
        await tester.enterText(find.byType(TextField).first, 'Aspirin');
        await tester.pumpAndSettle();

        // Select Tablet (has stock card).
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        // Fill ONLY the remaining-stock field — leave total blank.
        await tester.enterText(
          find.byKey(const ValueKey('medsAddStockRemaining')),
          '10',
        );
        await tester.pumpAndSettle();

        // Add one intake time (08:00). Tablet shows stepper + stock, so the
        // time chip may be below the 600px test viewport — scroll first.
        await tester.ensureVisible(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '08', minute: '00');

        // Tap Save — scroll it into view first.
        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Success.
        expect(find.text('Medication saved'), findsOneWidget);
        expect(find.byType(AddMedicationModal), findsNothing);

        final captured = recordingRepo.captured;
        expect(captured, isNotNull);

        // Both remaining AND total must parse for PackStock to be built.
        // Total was left blank → stock must be null.
        expect(captured!.stock, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // (7) Gap 2 times error: no intake time added → medsAddSaveErrorTimes SnackBar.
    // -------------------------------------------------------------------------
    testWidgets(
      'Gap2-times-error: no time added shows medsAddSaveErrorTimes SnackBar and modal stays (spec 032)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final overrides = [
          addMedicationProvider.overrideWith(
            (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
          ),
        ];

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: overrides,
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Fill name and select Inhaler (no extra conditional fields).
        await tester.enterText(find.byType(TextField).first, 'Ventolin');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inhaler'));
        await tester.pumpAndSettle();

        // Do NOT add any intake time.

        // Tap Save.
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Error SnackBar for missing times.
        expect(find.text('Add at least one intake time'), findsOneWidget);

        // Modal must NOT have popped.
        expect(find.byType(AddMedicationModal), findsOneWidget);

        // The recording repo must NOT have been called (validation fires first).
        expect(recordingRepo.captured, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // (8) Gap 2 duration error: Course selected + duration cleared → medsAddSaveErrorDuration.
    // -------------------------------------------------------------------------
    testWidgets(
      'Gap2-duration-error: Course with blank duration shows medsAddSaveErrorDuration SnackBar (spec 032)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final overrides = [
          addMedicationProvider.overrideWith(
            (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
          ),
        ];

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: overrides,
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Fill name and select Inhaler.
        await tester.enterText(find.byType(TextField).first, 'Ventolin');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inhaler'));
        await tester.pumpAndSettle();

        // Add one intake time so the times-required validation passes.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '09', minute: '00');

        // Switch to Course intake type.
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddIntakeTypeSegmented')),
            matching: find.text('Course'),
          ),
        );
        await tester.pumpAndSettle();

        // Clear the duration field — leaves it blank (parses as 0 → invalid).
        // Scroll the duration field into view first (Course card may be below viewport).
        await tester.ensureVisible(
          find.byKey(const ValueKey('medsAddCourseDuration')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          '',
        );
        await tester.pumpAndSettle();

        // Tap Save — scroll into view since Course card pushes it further down.
        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Error SnackBar for invalid duration.
        expect(
          find.text('Course duration must be at least 1 day'),
          findsOneWidget,
        );

        // Modal must NOT have popped.
        expect(find.byType(AddMedicationModal), findsOneWidget);

        // Repo was not called.
        expect(recordingRepo.captured, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // (9) dose error (new): Syrup with blank dose field → medsAddSaveErrorDose.
    //
    // When hasDose is true and the dose field is blank, _onSave builds
    // Dosage(amount: 0, unit: ml), which the use case rejects with
    // ValidationFailure(field: 'dose').
    // -------------------------------------------------------------------------
    testWidgets(
      'dose-error: Syrup with blank dose field shows medsAddSaveErrorDose SnackBar (spec 032)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final overrides = [
          addMedicationProvider.overrideWith(
            (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
          ),
        ];

        await tester.pumpWidget(
          _persistenceHarness(
            locale: const Locale('en'),
            overrides: overrides,
          ),
        );
        await tester.pumpAndSettle();
        await _openModal(tester);

        // Fill name and select Syrup (shows dose field).
        await tester.enterText(find.byType(TextField).first, 'Amoxicillin Syrup');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Syrup'));
        await tester.pumpAndSettle();

        // Leave the dose field BLANK — do NOT enter any text.

        // Add one intake time so the times-required validation passes.
        await tester.tap(find.widgetWithText(ActionChip, 'Time'));
        await tester.pumpAndSettle();
        await _pickTimeInDialog(tester, hour: '08', minute: '00');

        // Tap Save.
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        // Error SnackBar for zero/blank dose.
        expect(find.text('Enter a dose greater than zero'), findsOneWidget);

        // Modal must NOT have popped.
        expect(find.byType(AddMedicationModal), findsOneWidget);

        // Repo was not called — validation short-circuited.
        expect(recordingRepo.captured, isNull);
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
    // (1) Three Dividers present unconditionally on a freshly pumped modal:
    //     one in the AppBar bottom border (M15) + two section dividers.
    testWidgets('renders exactly three Dividers with no form selected', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsNWidgets(3));
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

    // (4) AC-1 — three Dividers remain when a form (Tablet) is selected.
    testWidgets(
      'renders exactly three Dividers with Tablet form selected',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.chevronDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tablet'));
        await tester.pumpAndSettle();

        expect(find.byType(Divider), findsNWidgets(3));
      },
    );

    // (5) AC-1 — three Dividers remain when Course intake type is selected.
    testWidgets(
      'renders exactly three Dividers with Course intake type selected',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Course'));
        await tester.pumpAndSettle();

        expect(find.byType(Divider), findsNWidgets(3));
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

  // ---------------------------------------------------------------------------
  // Edit mode (spec 036)
  // ---------------------------------------------------------------------------

  /// A tablet+continuous fixture WITH notes and a stable startDate.
  ///
  /// Used by the Gap-6/7 test to verify that Save does NOT wipe notes or
  /// reset a Continuous startDate to today.
  Medication continuousEditFixture() => Medication(
    id: const MedicationId('edit-cont-001'),
    name: 'Vitamin D',
    form: MedicationForm.tablet,
    type: MedicationType.continuous(startDate: DateTime.utc(2025, 1, 15)),
    schedule: const Schedule(
      slots: [
        TimeSlot(
          id: TimeSlotId('slot-cont-001'),
          minuteOfDay: 540, // 09:00
        ),
      ],
    ),
    dosePerIntake: const Dosage(amount: 1, unit: DoseUnit.tablet),
    notes: 'Take with food',
    createdAt: DateTime.utc(2025, 1, 15),
  );

  /// A tablet+course fixture that exercises all pre-fill paths:
  /// hasQuantity + hasStock form, two TimeSlots, CourseType (so the CourseCard
  /// is rendered), non-null Dosage, non-null PackStock.
  Medication editFixture() => Medication(
    id: const MedicationId('edit-test-001'),
    name: 'Ibuprofen',
    form: MedicationForm.tablet,
    type: MedicationType.course(
      startDate: DateTime.utc(2026, 4, 1),
      durationDays: 14,
      pauseDays: 7,
    ),
    schedule: const Schedule(
      slots: [
        TimeSlot(
          id: TimeSlotId('slot-edit-001'),
          minuteOfDay: 480, // 08:00
        ),
        TimeSlot(
          id: TimeSlotId('slot-edit-002'),
          minuteOfDay: 1200, // 20:00
        ),
      ],
    ),
    dosePerIntake: const Dosage(amount: 2.0, unit: DoseUnit.tablet),
    stock: const PackStock(remaining: 20, total: 28, warnAt: 5),
    createdAt: DateTime.utc(2026, 4, 1),
  );

  /// Builds a ProviderScope + MaterialApp where [AddMedicationModal(initial:)]
  /// is pushed on top of a base route — mirrors [_persistenceHarness] but for
  /// edit mode.
  Widget editPersistenceHarness({
    required Locale locale,
    required List<Override> overrides,
    required Medication initial,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: resolveAppLocale,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const ValueKey('openEditModal'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => AddMedicationModal(initial: initial),
                ),
              ),
              child: const Text('Open Edit'),
            ),
          ),
        ),
      ),
    );
  }

  group('AddMedicationModal edit mode (spec 036)', () {
    // Fixed clock for deterministic start-date rendering in the CourseCard.
    final editClock = Clock.fixed(DateTime(2026, 4, 1));

    // -------------------------------------------------------------------------
    // (1) Pre-fill — name field and AppBar title.
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: name field pre-filled and AppBar shows medsEditTitle (spec 036)',
      (tester) async {
        final fixture = editFixture();
        await withClock(editClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: [
                editMedicationProvider.overrideWith(
                  (_) => EditMedication(
                    _RecordingMedicationRepository(),
                    _FakeIdGenerator(),
                  ),
                ),
              ],
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();
        });

        // AppBar title is the edit title, not the add title.
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Edit medication'),
          ),
          findsOneWidget,
        );

        // Name TextField contains the fixture's name.
        final nameField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(nameField.controller?.text, 'Ibuprofen');
      },
    );

    // -------------------------------------------------------------------------
    // (2) Pre-fill — form picker collapsed display shows the tablet form name.
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: form picker collapsed display shows Tablet, not placeholder (spec 036)',
      (tester) async {
        final fixture = editFixture();
        await withClock(editClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: [
                editMedicationProvider.overrideWith(
                  (_) => EditMedication(
                    _RecordingMedicationRepository(),
                    _FakeIdGenerator(),
                  ),
                ),
              ],
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();
        });

        // "Tablet" should be visible in the collapsed display row.
        expect(find.text('Tablet'), findsOneWidget);

        // The placeholder must NOT appear — a form is already selected.
        expect(find.text('Choose a form'), findsNothing);
      },
    );

    // -------------------------------------------------------------------------
    // (3) Pre-fill — intake chips show the fixture's two time slots.
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: two InputChips pre-filled with 08:00 and 20:00 (spec 036)',
      (tester) async {
        final fixture = editFixture();
        await withClock(editClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: [
                editMedicationProvider.overrideWith(
                  (_) => EditMedication(
                    _RecordingMedicationRepository(),
                    _FakeIdGenerator(),
                  ),
                ),
              ],
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();
        });

        // Two chips — one per slot.
        expect(find.byType(InputChip), findsNWidgets(2));
        expect(find.text('08:00'), findsOneWidget);
        expect(find.text('20:00'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // (4) Pre-fill — Course segment selected; CourseCard visible with values.
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: Course segment selected; CourseCard shows duration 14 and pause 7 (spec 036)',
      (tester) async {
        final fixture = editFixture();
        await withClock(editClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: [
                editMedicationProvider.overrideWith(
                  (_) => EditMedication(
                    _RecordingMedicationRepository(),
                    _FakeIdGenerator(),
                  ),
                ),
              ],
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();
        });

        // CourseCard is visible — the segmented button pre-selected Course.
        expect(
          find.byKey(const ValueKey('medsAddCourseDuration')),
          findsOneWidget,
        );

        // Duration field shows the fixture's 14 days.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCourseDuration')),
            matching: find.text('14'),
          ),
          findsOneWidget,
        );

        // Pause field shows the fixture's 7 days.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medsAddCoursePause')),
            matching: find.text('7'),
          ),
          findsOneWidget,
        );
      },
    );

    // -------------------------------------------------------------------------
    // (5) Save routes to editMedicationProvider; add path NOT taken.
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: Save calls update (capturedUpdate set) and NOT add (captured null); '
      'shows medsEditSaveSuccess SnackBar and pops modal (spec 036)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(editClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: [
                editMedicationProvider.overrideWith(
                  (_) => EditMedication(recordingRepo, _FakeIdGenerator()),
                ),
                // Override addMedicationProvider with the same recording repo
                // so that if the add path were accidentally taken, `captured`
                // would be set (the assertion below would then catch it).
                addMedicationProvider.overrideWith(
                  (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
                ),
              ],
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          // Confirm the modal is open.
          expect(find.byType(AddMedicationModal), findsOneWidget);

          // Change the name so we can verify the updated value is forwarded.
          await tester.enterText(
            find.byType(TextField).first,
            'Ibuprofen 400mg',
          );
          await tester.pumpAndSettle();

          // Tap Save — scroll into view since CourseCard pushes it below viewport.
          await tester.ensureVisible(
            find.byKey(const ValueKey('medsAddSaveButton')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('medsAddSaveButton')));
          await tester.pumpAndSettle();

          // update was called; add was NOT called.
          expect(
            recordingRepo.capturedUpdate,
            isNotNull,
            reason: 'editMedicationProvider.update must have been called',
          );
          expect(
            recordingRepo.captured,
            isNull,
            reason:
                'addMedicationProvider.add must NOT have been called in edit mode',
          );

          // W3: the modal forwarded the EDITED name to editMedicationProvider.
          expect(
            recordingRepo.capturedUpdate?.name,
            'Ibuprofen 400mg',
            reason:
                'editMedicationProvider must receive the edited name, not the original',
          );

          // medsEditSaveSuccess SnackBar appears.
          expect(find.text('Medication updated'), findsOneWidget);

          // Modal is popped — the launcher button is visible again.
          expect(find.byType(AddMedicationModal), findsNothing);
          expect(find.byKey(const ValueKey('openEditModal')), findsOneWidget);
        });
      },
    );

    // -------------------------------------------------------------------------
    // (Gap 2) Validation failure in edit mode — does NOT pop, shows error.
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: clearing the name → Save shows error SnackBar and does NOT pop (spec 036)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(editClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: [
                editMedicationProvider.overrideWith(
                  (_) => EditMedication(recordingRepo, _FakeIdGenerator()),
                ),
                addMedicationProvider.overrideWith(
                  (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
                ),
              ],
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          // Confirm the modal is open.
          expect(find.byType(AddMedicationModal), findsOneWidget);

          // Clear the name field to trigger a ValidationFailure(field:'name').
          await tester.enterText(find.byType(TextField).first, '');
          await tester.pumpAndSettle();

          // Tap Save — scroll into view as the layout may push it off-screen.
          await tester.ensureVisible(
            find.byKey(const ValueKey('medsAddSaveButton')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('medsAddSaveButton')));
          await tester.pumpAndSettle();

          // Error SnackBar must be shown.
          expect(
            find.text('Enter a medication name'),
            findsOneWidget,
            reason: 'medsAddSaveErrorName SnackBar must appear on name validation failure',
          );

          // Modal must NOT have popped — it is still visible.
          expect(
            find.byType(AddMedicationModal),
            findsOneWidget,
            reason: 'Modal must stay open when validation fails',
          );

          // The launcher button on the base route must NOT be visible — the
          // modal is still on top.
          expect(
            find.text('Open Edit'),
            findsNothing,
            reason: 'Base route must still be hidden behind the modal',
          );

          // Validation short-circuits before hitting the repository.
          expect(
            recordingRepo.capturedUpdate,
            isNull,
            reason: 'repository.update must NOT be called when validation fails',
          );
          expect(
            recordingRepo.captured,
            isNull,
            reason: 'repository.add must NOT be called when validation fails',
          );
        });
      },
    );

    // -------------------------------------------------------------------------
    // (Gaps 6 + 7) Save preserves notes and Continuous startDate.
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: Save preserves notes and an already-Continuous startDate (spec 036)',
      (tester) async {
        final recordingRepo = _RecordingMedicationRepository();
        final fixture = continuousEditFixture();

        await withClock(editClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: [
                editMedicationProvider.overrideWith(
                  (_) => EditMedication(recordingRepo, _FakeIdGenerator()),
                ),
                addMedicationProvider.overrideWith(
                  (_) => AddMedication(recordingRepo, _FakeIdGenerator()),
                ),
              ],
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          // Confirm the modal is open.
          expect(find.byType(AddMedicationModal), findsOneWidget);

          // Change the name so there is a genuine edit to submit.
          await tester.enterText(find.byType(TextField).first, 'Vitamin D3');
          await tester.pumpAndSettle();

          // Tap Save.
          await tester.ensureVisible(
            find.byKey(const ValueKey('medsAddSaveButton')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('medsAddSaveButton')));
          await tester.pumpAndSettle();

          // The update path must have been taken.
          expect(
            recordingRepo.capturedUpdate,
            isNotNull,
            reason: 'editMedicationProvider.update must have been called',
          );

          // Edited name forwarded correctly.
          expect(
            recordingRepo.capturedUpdate?.name,
            'Vitamin D3',
            reason: 'Edited name must be forwarded to the repository',
          );

          // Notes must be preserved — not wiped to null.
          expect(
            recordingRepo.capturedUpdate?.notes,
            'Take with food',
            reason: 'notes must be preserved through the edit/update path',
          );

          // Continuous startDate must be preserved — NOT restamped to today.
          expect(
            recordingRepo.capturedUpdate?.type,
            isA<ContinuousType>().having(
              (c) => c.startDate,
              'startDate',
              DateTime.utc(2025, 1, 15),
            ),
            reason:
                'type must remain ContinuousType and startDate must not be reset to clock.now()',
          );
        });
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Delete affordance and flow (spec 037-meds-delete)
  //
  // Reuses editPersistenceHarness/editFixture from the spec-036 edit-mode
  // group above so the modal is pushed on top of a base route and
  // Navigator.pop is observable — the same setup the edit-mode Save-success
  // test (AC-10/AC-11 assertions below) relies on. Only deleteMedicationProvider
  // is overridden: _onDelete never reads addMedicationProvider/
  // editMedicationProvider, so those are left at their defaults (unused,
  // never constructed, since Riverpod providers are lazy).
  // ---------------------------------------------------------------------------
  group('AddMedicationModal delete (spec 037)', () {
    // Fixed clock — mirrors the spec-036 edit-mode group so CourseCard
    // rendering (driven by editFixture()'s Course type) is deterministic.
    final deleteClock = Clock.fixed(DateTime(2026, 4, 1));

    const deleteTooltip = 'Delete medication';

    List<Override> buildDeleteOverrides(_RecordingMedicationRepository repo) => [
      deleteMedicationProvider.overrideWith((_) => DeleteMedication(repo)),
    ];

    // -------------------------------------------------------------------------
    // (1) AC-7 — trash action is present in edit mode, found via its tooltip
    // (not find.byIcon — MEMORY F035: an unscoped byIcon lookup is ambiguous
    // once a glyph appears more than once on screen; the tooltip is unique).
    // -------------------------------------------------------------------------
    testWidgets(
      'edit mode: trash action is present, found via its tooltip (spec 037)',
      (tester) async {
        final repo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();
        });

        expect(find.byTooltip(deleteTooltip), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // (2) AC-7 — trash action is absent in add mode (initial: null).
    // -------------------------------------------------------------------------
    testWidgets(
      'add mode: trash action is absent (spec 037)',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.byTooltip(deleteTooltip), findsNothing);
      },
    );

    // -------------------------------------------------------------------------
    // (3) AC-8 — tapping the trash action shows an AlertDialog naming the
    // fixture medication.
    // -------------------------------------------------------------------------
    testWidgets(
      'tapping trash opens an AlertDialog whose body names the medication (spec 037)',
      (tester) async {
        final repo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip(deleteTooltip));
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.textContaining(fixture.name),
            ),
            findsOneWidget,
          );
        });
      },
    );

    // -------------------------------------------------------------------------
    // (4) AC-9 — Cancel dismisses the dialog, the modal remains, and the
    // delete use case is never invoked.
    // -------------------------------------------------------------------------
    testWidgets(
      'tapping Cancel dismisses the dialog without invoking delete (spec 037)',
      (tester) async {
        final repo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip(deleteTooltip));
          await tester.pumpAndSettle();

          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Cancel'),
            ),
          );
          await tester.pumpAndSettle();

          // Dialog is gone.
          expect(find.byType(AlertDialog), findsNothing);

          // Modal remains — the edit-mode AppBar title is still visible.
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Edit medication'),
            ),
            findsOneWidget,
          );

          // Delete use case was never invoked.
          expect(repo.deleteCallCount, 0);
          expect(repo.capturedDeleteId, isNull);
        });
      },
    );

    // -------------------------------------------------------------------------
    // (5) AC-10 — confirming delete (Right branch) invokes the use case
    // exactly once with the original id, pops the modal, and shows the
    // localized success SnackBar. Asserted the same way the spec-036
    // Save-success test asserts pop + SnackBar.
    // -------------------------------------------------------------------------
    testWidgets(
      'confirming delete calls the use case once, pops the modal, and shows medsDeleteSuccess (spec 037)',
      (tester) async {
        final repo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          // Confirm the modal is open before acting.
          expect(find.byType(AddMedicationModal), findsOneWidget);

          await tester.tap(find.byTooltip(deleteTooltip));
          await tester.pumpAndSettle();

          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Delete'),
            ),
          );
          await tester.pumpAndSettle();

          // Use case invoked exactly once with the original medication's id.
          expect(repo.deleteCallCount, 1);
          expect(repo.capturedDeleteId, fixture.id);

          // Success SnackBar (medsDeleteSuccess).
          expect(find.text('Medication deleted'), findsOneWidget);

          // Modal is popped — base route (launcher button) is visible again,
          // exactly like the spec-036 Save-success assertion.
          expect(find.byType(AddMedicationModal), findsNothing);
          expect(find.byKey(const ValueKey('openEditModal')), findsOneWidget);
        });
      },
    );

    // -------------------------------------------------------------------------
    // (6) AC-11 — confirming delete when the repository returns Left shows
    // the localized error SnackBar and the modal stays open.
    // -------------------------------------------------------------------------
    testWidgets(
      'confirming delete on a Left failure shows medsDeleteError and modal stays open (spec 037)',
      (tester) async {
        final repo = _RecordingMedicationRepository()
          ..deleteResult = const Left(Failure.cache('disk write failed'));
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip(deleteTooltip));
          await tester.pumpAndSettle();

          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Delete'),
            ),
          );
          await tester.pumpAndSettle();

          // Use case was still invoked exactly once.
          expect(repo.deleteCallCount, 1);

          // Error SnackBar (medsDeleteError).
          expect(
            find.text("Couldn't delete medication. Please try again."),
            findsOneWidget,
          );

          // Dialog is gone but the modal itself stays open.
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.byType(AddMedicationModal), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Edit medication'),
            ),
            findsOneWidget,
          );
        });
      },
    );

    // -------------------------------------------------------------------------
    // (7) AC-12 — the trash IconButton is disabled while a delete is in
    // flight. Mirrors the spec-032 "FilledButton.onPressed is null while save
    // is in flight" test's Completer technique, but drives the trash action
    // instead of Save.
    // -------------------------------------------------------------------------
    testWidgets(
      'trash IconButton.onPressed is null while delete is in flight (spec 037)',
      (tester) async {
        final completer = Completer<Either<Failure, void>>();
        final repo = _RecordingMedicationRepository()
          ..deleteCompleter = completer;
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('en'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip(deleteTooltip));
          await tester.pumpAndSettle();

          // Confirm the dialog — the completer never resolves, so the
          // delete call stays in flight after the dialog dismisses.
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Delete'),
            ),
          );
          await tester.pumpAndSettle();

          // The trash button must be disabled while the delete is pending.
          // find.byTooltip locates the Tooltip wrapping the IconButton's
          // child, so the IconButton itself is an ancestor of that match.
          final button = tester.widget<IconButton>(
            find.ancestor(
              of: find.byTooltip(deleteTooltip),
              matching: find.byType(IconButton),
            ),
          );
          expect(button.onPressed, isNull);

          // Resolve the completer to clean up pending timers so the test
          // runner doesn't report outstanding async work.
          completer.complete(const Right(null));
          await tester.pumpAndSettle();
        });
      },
    );

    // -------------------------------------------------------------------------
    // (8) AC-13 — DE locale: tooltip and dialog title render the German ARB
    // strings, not the English fallback.
    // -------------------------------------------------------------------------
    testWidgets(
      "DE locale: trash tooltip and dialog title render 'Medikament löschen' / 'Medikament löschen?' (spec 037)",
      (tester) async {
        final repo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('de'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          // Translated tooltip is present.
          expect(find.byTooltip('Medikament löschen'), findsOneWidget);

          await tester.tap(find.byTooltip('Medikament löschen'));
          await tester.pumpAndSettle();

          // Translated dialog title is present.
          expect(find.text('Medikament löschen?'), findsOneWidget);
        });
      },
    );

    // -------------------------------------------------------------------------
    // (9) AC-13 — UK locale: tooltip and dialog title render the Ukrainian
    // ARB strings, not the English fallback.
    // -------------------------------------------------------------------------
    testWidgets(
      "UK locale: trash tooltip and dialog title render 'Видалити ліки' / 'Видалити ліки?' (spec 037)",
      (tester) async {
        final repo = _RecordingMedicationRepository();
        final fixture = editFixture();

        await withClock(deleteClock, () async {
          await tester.pumpWidget(
            editPersistenceHarness(
              locale: const Locale('uk'),
              overrides: buildDeleteOverrides(repo),
              initial: fixture,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('openEditModal')));
          await tester.pumpAndSettle();

          // Translated tooltip is present.
          expect(find.byTooltip('Видалити ліки'), findsOneWidget);

          await tester.tap(find.byTooltip('Видалити ліки'));
          await tester.pumpAndSettle();

          // Translated dialog title is present.
          expect(find.text('Видалити ліки?'), findsOneWidget);
        });
      },
    );
  });
}
