/// The single business operation that reconciles today's overdue doses into
/// persisted `missed` intake rows — the orchestration layer of the auto-miss
/// engine.
///
/// [ReconcileMissedIntakes] snapshots the tracked medications and stored
/// intakes at a caller-supplied instant, runs the pure [findAutoMissDoses]
/// derivation to decide which occurrences are past their intake window and have
/// no row yet, and writes one `missed` [Intake] per eligible occurrence via
/// [IntakeRepository.markMissed]. Pure Dart (constitution §2.1) — no Flutter,
/// drift, or uuid imports. The only cross-feature dependency is the settings
/// domain's public API ([SettingsRepository] + [IntakeWindow]), a permitted
/// domain→domain import.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/id/id_generator.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../settings/domain/value_objects/intake_window.dart';
import '../entities/intake.dart';
import '../entities/intake_status.dart';
import '../repositories/intake_repository.dart';
import '../repositories/medication_repository.dart';
import '../value_objects/intake_id.dart';
import '../value_objects/missed_intake_reconciliation.dart';

/// Reconciles the current medication/intake state into `missed` intake rows for
/// every due occurrence whose intake window has closed with no recorded intake.
///
/// This is the write-side counterpart to the pure [findAutoMissDoses]
/// derivation. On each [call] it reads the intake window from settings, takes a
/// point-in-time snapshot of medications and stored intakes, derives the
/// eligible occurrences, and persists one `missed` [Intake] per occurrence.
///
/// Behavioural contract:
///
/// * **Idempotent** — a second run over the same state writes nothing, because
///   the derivation excludes any occurrence that already has a stored intake
///   row (matched by occurrence key), so no already-reconciled dose is re-missed.
/// * **Never clobbers user intent** — eligibility itself excludes any occurrence
///   with an existing `taken`/`skipped`/`missed` row, so a user-recorded intake
///   is never overwritten. [IntakeRepository.markMissed]'s insert-or-ignore is
///   defense-in-depth, not the primary guard.
/// * **Resilient window read** — if settings cannot be read the default
///   [IntakeWindow.defaultValue] is used, so a settings failure never blocks
///   reconciliation.
/// * **Single-day scope** — the derivation reasons only about the local calendar
///   day of `now`; back-filling older days is out of scope.
/// * **Fail-fast on write** — on the first repository write failure the loop
///   stops and returns that [Failure]; occurrences already written stay written,
///   and the next trigger reconciles the remainder (idempotency makes this safe).
class ReconcileMissedIntakes {
  /// Creates a [ReconcileMissedIntakes] use case backed by [_medicationRepository]
  /// and [_intakeRepository] for the state snapshot and `missed` writes,
  /// [_settingsRepository] for the intake window, and [_idGenerator] for minting
  /// each new intake ID.
  const ReconcileMissedIntakes(
    this._medicationRepository,
    this._intakeRepository,
    this._settingsRepository,
    this._idGenerator,
  );

  final MedicationRepository _medicationRepository;
  final IntakeRepository _intakeRepository;
  final SettingsRepository _settingsRepository;
  final IdGenerator _idGenerator;

  /// Reconciles overdue doses as of [now], returning the number of `missed`
  /// intakes written on success or the first [Failure] encountered.
  ///
  /// Reads the intake window from settings (falling back to
  /// [IntakeWindow.defaultValue] on a [Left] so a settings failure never blocks
  /// reconciliation), snapshots medications and intakes via `watchAll().first`
  /// (short-circuiting with the surfaced [Left] and writing nothing if either
  /// read fails), derives the eligible occurrences with [findAutoMissDoses], and
  /// persists a `missed` [Intake] per occurrence via
  /// [IntakeRepository.markMissed]. The write loop is fail-fast: the first write
  /// [Left] is returned immediately. `now` is injected (never
  /// `DateTime.now()`) so the derivation stays deterministic.
  Future<Either<Failure, int>> call({required DateTime now}) async {
    final IntakeWindow window = _settingsRepository.load().fold(
      (_) => IntakeWindow.defaultValue,
      (settings) => settings.intakeWindow,
    );

    final medsEither = await _medicationRepository.watchAll().first;

    return medsEither.fold(
      (failure) async => Left<Failure, int>(failure),
      (meds) async {
        final intakesEither = await _intakeRepository.watchAll().first;

        return intakesEither.fold(
          (failure) async => Left<Failure, int>(failure),
          (intakes) async {
            final eligible = findAutoMissDoses(
              meds: meds,
              intakes: intakes,
              window: window,
              now: now,
            );

            var count = 0;
            for (final d in eligible) {
              final intake = Intake(
                id: IntakeId(_idGenerator.newId()),
                medicationId: d.medication.id,
                slotId: d.slot.id,
                scheduledAt: d.scheduledAt,
                confirmedAt: null,
                status: IntakeStatus.missed,
                notes: null,
              );

              final result = await _intakeRepository.markMissed(intake);
              final failure = result.fold((f) => f, (_) => null);
              if (failure != null) {
                return Left<Failure, int>(failure);
              }
              count += 1;
            }

            return Right<Failure, int>(count);
          },
        );
      },
    );
  }
}
