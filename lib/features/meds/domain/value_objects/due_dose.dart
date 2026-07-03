/// Expansion of the tracked medications into the individual doses due on a
/// given local calendar day — the algorithmic heart of the Today screen.
///
/// Pure, clock-free derivation of the medication domain model — no Flutter,
/// drift, or uuid imports (constitution §2.1). The current instant is passed
/// in as [expandDueDoses]'s `now`, so callers control time (via
/// `package:clock` in production, fixed clocks in tests). See [DueDose] and
/// [expandDueDoses].
library;

import '../entities/course_phase.dart';
import '../entities/dosage.dart';
import '../entities/medication.dart';
import '../entities/medication_activity_status.dart';
import '../entities/medication_type.dart';
import '../entities/time_slot.dart';
import 'course_progress.dart';
import 'local_calendar_date.dart';
import 'medication_activity.dart';

/// A single medication dose that is due on a particular calendar day.
///
/// One [DueDose] is produced per [TimeSlot] of a medication that is active on
/// the day in question. It pairs the source [medication] and [slot] with the
/// [effectiveDose] actually taken (the slot override, or the medication
/// default) and the concrete [scheduledAt] instant the dose is due at.
/// Immutable value object; all fields are `final`.
class DueDose {
  /// Creates a [DueDose] for [slot] of [medication].
  const DueDose({
    required this.medication,
    required this.slot,
    required this.effectiveDose,
    required this.scheduledAt,
  });

  /// The medication this dose belongs to.
  final Medication medication;

  /// The schedule time slot that produced this dose.
  final TimeSlot slot;

  /// The dose actually due for this occurrence: the slot's
  /// [TimeSlot.doseOverride] when set, otherwise the medication's
  /// [Medication.dosePerIntake]. `null` when neither is recorded.
  final Dosage? effectiveDose;

  /// The instant this dose is due, in **UTC**.
  ///
  /// Built from the LOCAL year/month/day of `now` plus the slot's wall-clock
  /// [TimeSlot.minuteOfDay], then converted to UTC. Storing in UTC keeps the
  /// value stable for persistence and comparison; render it in local time for
  /// display.
  final DateTime scheduledAt;
}

/// Expands [meds] into the flat, ordered list of [DueDose]s due on the LOCAL
/// calendar day of [now].
///
/// A medication contributes one [DueDose] per [TimeSlot] in its schedule when
/// it is due today. "Due today" is decided per [MedicationType]:
///
/// * [ContinuousType] — due once its (local) start day has arrived, i.e. the
///   local calendar date of [now] is not before the local start date. A
///   future-dated start yields no doses.
/// * [CourseType] — due only when ALL of the following hold: the local start
///   day has arrived, the course has not [MedicationActivityStatus.completed]
///   (see [resolveMedicationActivity]), and the course is in an
///   [CoursePhase.activeWindow] rather than a pause gap today (see
///   [CourseProgress.resolve]). This excludes future starts, finished
///   non-cyclic courses, and cyclic pause-gap days.
///
/// For each due medication, every slot becomes a [DueDose] whose
/// [DueDose.effectiveDose] is the slot override or the medication default, and
/// whose [DueDose.scheduledAt] is the UTC instant of today's date at the
/// slot's [TimeSlot.minuteOfDay].
///
/// The result is sorted ascending by [TimeSlot.minuteOfDay]; ties are broken
/// by medication [Medication.name] (case-insensitive) and then by
/// [TimeSlot.id] value, so the ordering is deterministic across medications
/// that share a slot time.
List<DueDose> expandDueDoses({
  required List<Medication> meds,
  required DateTime now,
}) {
  final DateTime today = localCalendarDate(now);
  final List<DueDose> doses = <DueDose>[];

  for (final Medication med in meds) {
    if (!_isDueToday(med, today: today, now: now)) {
      continue;
    }
    for (final TimeSlot slot in med.schedule.slots) {
      doses.add(
        DueDose(
          medication: med,
          slot: slot,
          effectiveDose: slot.doseOverride ?? med.dosePerIntake,
          scheduledAt: DateTime(
            now.year,
            now.month,
            now.day,
            slot.minuteOfDay ~/ 60,
            slot.minuteOfDay % 60,
          ).toUtc(),
        ),
      );
    }
  }

  doses.sort(_compareDueDoses);
  return doses;
}

/// Whether [med] has a dose due on [today] (the local calendar date of [now]).
///
/// Exhaustively handles every [MedicationType] variant so the compiler flags
/// any future variant added to the sealed union — there is no `default`.
bool _isDueToday(
  Medication med, {
  required DateTime today,
  required DateTime now,
}) {
  final MedicationType type = med.type;
  switch (type) {
    case ContinuousType(:final DateTime startDate):
      // Due from the start day onward; a future start contributes nothing.
      return !today.isBefore(localCalendarDate(startDate));
    case CourseType():
      // `type` is promoted to CourseType here — no cast needed.
      final bool started = !today.isBefore(localCalendarDate(type.startDate));
      final bool active =
          resolveMedicationActivity(med, now) ==
          MedicationActivityStatus.active;
      final bool inWindow =
          CourseProgress.resolve(course: type, now: now).phase ==
          CoursePhase.activeWindow;
      return started && active && inWindow;
  }
}

/// Orders two [DueDose]s: ascending [TimeSlot.minuteOfDay], then medication
/// name (case-insensitive), then [TimeSlot.id] value.
int _compareDueDoses(DueDose a, DueDose b) {
  final int byMinute = a.slot.minuteOfDay.compareTo(b.slot.minuteOfDay);
  if (byMinute != 0) {
    return byMinute;
  }
  final int byName = a.medication.name.toLowerCase().compareTo(
    b.medication.name.toLowerCase(),
  );
  if (byName != 0) {
    return byName;
  }
  return a.slot.id.value.compareTo(b.slot.id.value);
}
