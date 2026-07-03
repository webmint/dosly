/// Pure shaping of the day's expanded due doses plus the stored intakes into
/// the render-ready structure backing the Today screen: one entry per due dose,
/// each carrying its derived [IntakeStatus] and an [TodayDose.undoable] grace
/// flag.
///
/// This is a `presentation/` view model. It depends only on the medication
/// `domain/` (entities, value objects, derivations) — never on Flutter, drift,
/// or the data layer. [buildTodayView] is pure and synchronous: it takes an
/// explicit [DateTime] `now` (injected by the screen via `clock.now()`) rather
/// than reading the wall clock itself, so it is unit-testable without pumping
/// widgets or freezing time globally. It mirrors `buildMedsListView`.
library;

import '../../domain/entities/intake.dart';
import '../../domain/entities/intake_status.dart';
import '../../domain/entities/medication.dart';
import '../../domain/value_objects/due_dose.dart';
import '../../domain/value_objects/intake_grace.dart';
import '../../domain/value_objects/intake_id.dart';
import '../../domain/value_objects/local_calendar_date.dart';

/// A single due dose ready for rendering on the Today screen, with its derived
/// lifecycle state attached.
///
/// Pairs the source [dose] (the medication + slot + scheduled instant produced
/// by [expandDueDoses]) with the state resolved against the stored intakes as of
/// a given instant: its [status] ([IntakeStatus.pending] when no intake row
/// exists yet), the [confirmedAt] timestamp of the matched intake (`null` when
/// unmatched or never confirmed), and whether the confirmation may still be
/// [undoable] within [kIntakeUndoGracePeriod].
///
/// Immutable: constructed once by [buildTodayView] and never mutated.
class TodayDose {
  /// Creates a [TodayDose] pairing [dose] with its derived intake state.
  const TodayDose({
    required this.dose,
    required this.status,
    required this.confirmedAt,
    required this.undoable,
    required this.intakeId,
  });

  /// The due dose this entry renders (medication, slot, effective dose, and the
  /// UTC instant it is scheduled at).
  final DueDose dose;

  /// The dose's derived lifecycle state as of the build instant:
  /// [IntakeStatus.pending] when no matching intake exists, otherwise the
  /// matched intake's status ([IntakeStatus.taken] / [IntakeStatus.skipped]).
  final IntakeStatus status;

  /// When the matched intake was confirmed, in **UTC**; `null` when there is no
  /// matching intake or it was never confirmed.
  final DateTime? confirmedAt;

  /// The identifier of the matched intake; `null` when this dose is
  /// [IntakeStatus.pending] with no stored intake yet. The Today screen needs
  /// this to call [UndoIntake], which operates on an intake id rather than a
  /// medication/slot/scheduled-time triple.
  final IntakeId? intakeId;

  /// Whether this dose's confirmation may still be reverted: `true` only when it
  /// has a non-pending [status], a non-null [confirmedAt], and the elapsed time
  /// since confirmation is within [kIntakeUndoGracePeriod] as of the build
  /// instant (inclusive boundary). Mirrors the `UndoIntake` grace-window rule.
  final bool undoable;
}

/// The fully-shaped data backing the Today screen.
///
/// Holds the ordered [doses] due on the local calendar day of the build
/// instant — one [TodayDose] per expanded [DueDose], preserving the ascending
/// time order established by [expandDueDoses]. [isEmpty] distinguishes the
/// "nothing is due today" empty state.
///
/// Immutable: produced once per build by [buildTodayView].
class TodayView {
  /// Creates a [TodayView] from its ordered list of shaped doses.
  const TodayView({required this.doses});

  /// The doses due today, in ascending schedule-time order (as produced by
  /// [expandDueDoses]), each with its derived intake state.
  final List<TodayDose> doses;

  /// Whether no doses are due today — drives the "nothing scheduled" empty
  /// state on the Today screen.
  bool get isEmpty => doses.isEmpty;
}

/// Shapes the day's due doses and stored [intakes] into a [TodayView] for
/// rendering as of [now].
///
/// Pure and synchronous, running in O(doses + intakes): the stored [intakes]
/// are indexed ONCE into a lookup map keyed by
/// `(medicationId, slotId, localCalendarDate(scheduledAt))`, after which each
/// due dose resolves its intake with a single O(1) map lookup — replacing the
/// former O(doses × intakes) linear rescan. The pipeline is:
///
/// 1. Expand [meds] into the flat, time-sorted list of doses due on the local
///    calendar day of [now] via [expandDueDoses].
/// 2. Index [intakes] into the occurrence map, computing [localCalendarDate]
///    exactly once per intake. Matching by local calendar date (not raw
///    instant) avoids the instant-equality trap, so an intake stored earlier
///    the same local day still matches. The DB unique key
///    `(medicationId, slotId, scheduledAt)` guarantees at most one intake per
///    occurrence, so each key holds a single row (last-write-wins is
///    equivalent should a key ever collide).
/// 3. For each [DueDose], look up its intake by
///    `(medication.id, slot.id, localCalendarDate(scheduledAt))`. Derive
///    [TodayDose.status] from the matched intake (else [IntakeStatus.pending]),
///    carry through its [TodayDose.confirmedAt], and compute
///    [TodayDose.undoable]: `true` only when the status is non-pending,
///    `confirmedAt` is non-null, and `now - confirmedAt` is within
///    [kIntakeUndoGracePeriod] (compared in UTC; the boundary is inclusive and
///    a future `confirmedAt` — a negative elapsed span — is never undoable).
///
/// Every due dose appears in the result regardless of whether its scheduled
/// time is past or future relative to [now]; the ascending time order from
/// [expandDueDoses] is preserved.
TodayView buildTodayView({
  required List<Medication> meds,
  required List<Intake> intakes,
  required DateTime now,
}) {
  final List<DueDose> due = expandDueDoses(meds: meds, now: now);

  // Index the stored intakes once so each due dose resolves in O(1). The record
  // key is (medicationId, slotId, local calendar date); localCalendarDate always
  // returns a UTC-midnight DateTime, so equal calendar days yield equal keys.
  final Map<(String, String, DateTime), Intake> byOccurrence =
      <(String, String, DateTime), Intake>{};
  for (final Intake intake in intakes) {
    byOccurrence[(
          intake.medicationId.value,
          intake.slotId.value,
          localCalendarDate(intake.scheduledAt),
        )] =
        intake;
  }

  final List<TodayDose> doses = <TodayDose>[
    for (final DueDose d in due) _shapeDose(d, byOccurrence, now),
  ];

  return TodayView(doses: doses);
}

/// Resolves a single [DueDose] against the pre-built [byOccurrence] index as of
/// [now].
///
/// Looks up the matching intake by the record key
/// `(medication.id, slot.id, localCalendarDate(scheduledAt))` — an O(1)
/// operation. Returns a [TodayDose] whose status is [IntakeStatus.pending] when
/// no intake is indexed for that occurrence.
TodayDose _shapeDose(
  DueDose d,
  Map<(String, String, DateTime), Intake> byOccurrence,
  DateTime now,
) {
  final Intake? matched =
      byOccurrence[(
        d.medication.id.value,
        d.slot.id.value,
        localCalendarDate(d.scheduledAt),
      )];
  final IntakeStatus status = matched?.status ?? IntakeStatus.pending;
  final DateTime? confirmedAt = matched?.confirmedAt;

  return TodayDose(
    dose: d,
    status: status,
    confirmedAt: confirmedAt,
    undoable: _isUndoable(status: status, confirmedAt: confirmedAt, now: now),
    intakeId: matched?.id,
  );
}

/// Whether a confirmation with [status] at [confirmedAt] may still be undone as
/// of [now]: non-pending, confirmed, and within [kIntakeUndoGracePeriod].
///
/// Compared in UTC. The boundary is inclusive (exactly the grace period is
/// still undoable); a future [confirmedAt] yields a negative elapsed span and is
/// never undoable.
bool _isUndoable({
  required IntakeStatus status,
  required DateTime? confirmedAt,
  required DateTime now,
}) {
  if (status == IntakeStatus.pending || confirmedAt == null) {
    return false;
  }
  final Duration elapsed = now.toUtc().difference(confirmedAt.toUtc());
  return !elapsed.isNegative && elapsed <= kIntakeUndoGracePeriod;
}
