/// Pure, clock-free derivation of which of today's due doses must be
/// auto-missed as of a given instant — the algorithmic core of the auto-miss
/// engine.
///
/// Pure Dart derivation of the medication domain model — no Flutter, drift, or
/// uuid imports (constitution §2.1). The only cross-feature dependency is the
/// settings `IntakeWindow` value object, a permitted domain→domain import. The
/// current instant is passed in as `now` so callers control time (via
/// `package:clock` in production, fixed instants in tests). See
/// [findAutoMissDoses].
///
/// ## Single-day scope
///
/// This derivation reasons only about the LOCAL calendar day of `now`: it reuses
/// [expandDueDoses] for single-day expansion and never looks backwards at
/// earlier days. Back-filling older days is out of scope.
///
/// ## Eligibility
///
/// A due occurrence is eligible to be auto-missed when ALL of the following
/// hold:
///
/// 1. it is due today (produced by [expandDueDoses] for the local day of `now`);
/// 2. its intake window has strictly closed —
///    `now > scheduledAt + window.minutes`, compared in UTC (the boundary
///    instant itself is NOT yet missed); and
/// 3. it has NO matching stored intake, matched by the occurrence key
///    `(medicationId.value, slotId.value, localCalendarDate(scheduledAt))` —
///    the same local-calendar-date keying `buildTodayView` uses, NOT raw-instant
///    equality.
library;

import '../../../settings/domain/value_objects/intake_window.dart';
import '../entities/intake.dart';
import '../entities/medication.dart';
import 'due_dose.dart';
import 'local_calendar_date.dart';

/// Derives the subset of today's due doses that must be auto-missed as of [now].
///
/// Reuses the existing single-day math rather than re-deriving it: [meds] are
/// expanded into today's doses via [expandDueDoses], and occurrences are matched
/// against [intakes] by the occurrence key
/// `(medicationId.value, slotId.value, localCalendarDate(scheduledAt))` — the
/// same local-calendar-date keying as `buildTodayView`, so an intake stored at a
/// different instant on the same local day still matches.
///
/// A returned [DueDose] satisfies all three eligibility conditions documented at
/// the library level: it is due today, its [window] has STRICTLY closed
/// (`now > scheduledAt + window.minutes`, compared in UTC — the boundary is not
/// yet missed), and no stored intake exists for its occurrence. The result
/// preserves the ascending schedule-time order established by [expandDueDoses].
///
/// Total and pure: for empty [meds] (or when every due dose is future, matched,
/// or exactly at the boundary) it returns an empty list.
List<DueDose> findAutoMissDoses({
  required List<Medication> meds,
  required List<Intake> intakes,
  required IntakeWindow window,
  required DateTime now,
}) {
  final List<DueDose> due = expandDueDoses(meds: meds, now: now);

  // Index the stored intakes' occurrence keys once; localCalendarDate always
  // returns a UTC-midnight DateTime, so equal calendar days yield equal keys.
  final Set<(String, String, DateTime)> present = <(String, String, DateTime)>{
    for (final Intake intake in intakes)
      (
        intake.medicationId.value,
        intake.slotId.value,
        localCalendarDate(intake.scheduledAt),
      ),
  };

  final DateTime nowUtc = now.toUtc();
  final Duration windowDuration = Duration(minutes: window.minutes);

  return <DueDose>[
    for (final DueDose d in due)
      if (!present.contains((
            d.medication.id.value,
            d.slot.id.value,
            localCalendarDate(d.scheduledAt),
          )) &&
          nowUtc.isAfter(d.scheduledAt.toUtc().add(windowDuration)))
        d,
  ];
}
