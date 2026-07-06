/// Pure shaping of the day's expanded due doses plus the stored intakes into
/// the render-ready structure backing the Today screen: doses bucketed into
/// hourly [TodayHourGroup]s, each dose carrying its derived [IntakeStatus], a
/// time-only [DoseWindowState] classification, an [TodayDose.actionable]
/// enablement flag, and an [TodayDose.undoable] grace flag, plus the
/// [TodayView.nextIntake] countdown target.
///
/// This is a `presentation/` view model. It depends only on the medication
/// `domain/` (entities, value objects, derivations) plus the settings
/// [IntakeWindow] value object — never on Flutter, drift, or the data layer.
/// [buildTodayView] is pure and synchronous: it takes an explicit [DateTime]
/// `now` (injected by the screen via `clock.now()`) and the three intake
/// settings ([IntakeWindow], grace [Duration], mark-ahead flag) rather than
/// reading the wall clock or providers itself, so it is unit-testable without
/// pumping widgets or freezing time globally. It mirrors `buildMedsListView`.
library;

import '../../../settings/domain/value_objects/intake_window.dart';
import '../../domain/entities/intake.dart';
import '../../domain/entities/intake_status.dart';
import '../../domain/entities/medication.dart';
import '../../domain/value_objects/due_dose.dart';
import '../../domain/value_objects/intake_id.dart';
import '../../domain/value_objects/local_calendar_date.dart';

/// Time-only classification of a dose relative to its intake window, computed
/// in **UTC** and independent of the dose's [IntakeStatus].
///
/// Derived from the dose's scheduled instant, `now`, and the configured
/// [IntakeWindow]. The `open`/`pastWindow` split dovetails with spec 040's
/// strict `now > windowClose` missed rule, so the two classifications have no
/// gap and no overlap.
enum DoseWindowState {
  /// `now` is before the scheduled instant: the intake window has not opened.
  future,

  /// `now` falls within the **inclusive** window
  /// `[scheduledAt, scheduledAt + intakeWindow]` — both boundaries count as
  /// open.
  open,

  /// `now` is strictly past the window close (`now > scheduledAt +
  /// intakeWindow`): the window has lapsed.
  pastWindow,
}

/// Aggregate window state of a [TodayHourGroup], derived from the per-dose
/// [DoseWindowState] of its members.
///
/// Drives the group header badge and the "now" accent on the Today screen.
enum TodayGroupState {
  /// Every dose in the group is [DoseWindowState.future].
  future,

  /// At least one dose is [DoseWindowState.open], or the group mixes future
  /// and past-window doses — the group is "live" as of the build instant.
  now,

  /// Every dose in the group is [DoseWindowState.pastWindow].
  past,
}

/// A single due dose ready for rendering on the Today screen, with its derived
/// lifecycle and time state attached.
///
/// Pairs the source [dose] (the medication + slot + scheduled instant produced
/// by [expandDueDoses]) with the state resolved against the stored intakes as of
/// a given instant: its [status] ([IntakeStatus.pending] when no intake row
/// exists yet), the [confirmedAt] timestamp of the matched intake (`null` when
/// unmatched or never confirmed), its time-only [windowState], whether it is
/// currently [actionable], and whether the confirmation may still be [undoable]
/// within the configured grace [Duration].
///
/// Immutable: constructed once by [buildTodayView] and never mutated.
class TodayDose {
  /// Creates a [TodayDose] pairing [dose] with its derived intake state.
  ///
  /// [windowState] and [actionable] carry defaults ([DoseWindowState.future],
  /// `false`) so a caller that only cares about [status]/[confirmedAt] may
  /// omit them; every real call site — [buildTodayView] and the current
  /// hand-written test fixtures — supplies both explicitly. Tracked as
  /// constitution §3.5 cleanup debt: the defaults have no live consumer and
  /// may be removed once confirmed unnecessary.
  const TodayDose({
    required this.dose,
    required this.status,
    required this.confirmedAt,
    required this.undoable,
    required this.intakeId,
    this.windowState = DoseWindowState.future,
    this.actionable = false,
  });

  /// The due dose this entry renders (medication, slot, effective dose, and the
  /// UTC instant it is scheduled at).
  final DueDose dose;

  /// The dose's derived lifecycle state as of the build instant:
  /// [IntakeStatus.pending] when no matching intake exists, otherwise the
  /// matched intake's status ([IntakeStatus.taken] / [IntakeStatus.skipped] /
  /// [IntakeStatus.missed]).
  final IntakeStatus status;

  /// When the matched intake was confirmed, in **UTC**; `null` when there is no
  /// matching intake or it was never confirmed.
  final DateTime? confirmedAt;

  /// The identifier of the matched intake; `null` when this dose is
  /// [IntakeStatus.pending] with no stored intake yet. The Today screen needs
  /// this to call [UndoIntake], which operates on an intake id rather than a
  /// medication/slot/scheduled-time triple.
  final IntakeId? intakeId;

  /// The dose's time-only [DoseWindowState] as of the build instant, computed
  /// in UTC from its scheduled instant and the configured [IntakeWindow].
  /// Independent of [status]: computed for every dose regardless of lifecycle.
  final DoseWindowState windowState;

  /// Whether a **pending** dose's confirm/skip affordances are interactive as
  /// of the build instant. Encodes the enablement matrix: [DoseWindowState.open]
  /// ⇒ `true`; [DoseWindowState.future] ⇒ the mark-ahead setting;
  /// [DoseWindowState.pastWindow] ⇒ `false`. Always `false` for a non-pending
  /// [status].
  final bool actionable;

  /// Whether this dose's confirmation may still be reverted: `true` only when it
  /// has a non-pending [status], a non-null [confirmedAt], and the elapsed time
  /// since confirmation is within the configured grace [Duration] as of the
  /// build instant (inclusive boundary). Mirrors the `UndoIntake` grace-window
  /// rule.
  final bool undoable;
}

/// A group of due doses that share the same wall-clock hour, ready for
/// rendering as one collapsible section on the Today screen.
///
/// Always holds at least one dose (empty hour buckets are never emitted). The
/// [doses] preserve the ascending schedule-time order established by
/// [expandDueDoses]. [state] aggregates the members' [DoseWindowState];
/// [takenCount] and [total] back the "✓ N/M" badge; [hasActionablePending]
/// gates the group's Mark-all affordance.
///
/// Immutable: produced once per build by [buildTodayView].
class TodayHourGroup {
  /// Creates a [TodayHourGroup] for wall-clock [hour] from its ordered [doses].
  const TodayHourGroup({
    required this.hour,
    required this.doses,
    required this.state,
    required this.takenCount,
  });

  /// The wall-clock hour bucket (0–23) = `slot.minuteOfDay ~/ 60`.
  final int hour;

  /// The doses in this hour, preserving the ascending schedule-time order from
  /// [expandDueDoses]. Never empty.
  final List<TodayDose> doses;

  /// The group's aggregate window state, derived from its doses'
  /// [DoseWindowState] values.
  final TodayGroupState state;

  /// The number of [doses] whose [TodayDose.status] is [IntakeStatus.taken] —
  /// the numerator of the group's "✓ N/M" badge. Always `<= total`.
  final int takenCount;

  /// The total number of doses in this group — `doses.length`, the badge
  /// denominator and count sub-label.
  int get total => doses.length;

  /// Whether any dose in this group is a pending, currently-[actionable] dose —
  /// gates the group's Mark-all button.
  bool get hasActionablePending => doses.any(
    (TodayDose d) => d.status == IntakeStatus.pending && d.actionable,
  );
}

/// The fully-shaped data backing the Today screen.
///
/// Holds the [groups] due on the local calendar day of the build instant —
/// doses bucketed by wall-clock hour, ascending by [TodayHourGroup.hour], each
/// group preserving the ascending time order established by [expandDueDoses].
/// [nextIntake] is the countdown target; [isEmpty] distinguishes the "nothing
/// is due today" empty state.
///
/// Immutable: produced once per build by [buildTodayView].
class TodayView {
  /// Creates a [TodayView] from its ordered [groups] and optional [nextIntake].
  const TodayView({required this.groups, this.nextIntake});

  /// The hour-bucketed groups due today, ascending by
  /// [TodayHourGroup.hour].
  final List<TodayHourGroup> groups;

  /// The countdown target: the soonest dose with
  /// [DoseWindowState.future] and [IntakeStatus.pending] status; `null` when no
  /// such dose exists (all done / nothing upcoming).
  final TodayDose? nextIntake;

  /// Whether no doses are due today — drives the "nothing scheduled" empty
  /// state on the Today screen.
  bool get isEmpty => groups.isEmpty;

  /// The doses due today flattened across [groups], in ascending schedule-time
  /// order.
  ///
  /// `TodayScreen` reads [groups] directly (never this getter) since the
  /// feature-041 redesign; this flattener is currently exercised only by
  /// hand-written unit tests that assert against a flat sequence. Tracked as
  /// constitution §3.5 cleanup debt — retained for now rather than rewriting
  /// every existing test assertion.
  List<TodayDose> get doses => <TodayDose>[
    for (final TodayHourGroup g in groups) ...g.doses,
  ];
}

/// Shapes the day's due doses and stored [intakes] into a [TodayView] for
/// rendering as of [now], given the three intake settings.
///
/// Pure and synchronous, running in O(doses + intakes): the stored [intakes]
/// are indexed ONCE into a lookup map keyed by
/// `(medicationId, slotId, localCalendarDate(scheduledAt))`, after which each
/// due dose resolves its intake with a single O(1) map lookup. The pipeline is:
///
/// 1. Expand [meds] into the flat, time-sorted list of doses due on the local
///    calendar day of [now] via [expandDueDoses].
/// 2. Index [intakes] into the occurrence map, computing [localCalendarDate]
///    exactly once per intake. Matching by local calendar date (not raw
///    instant) avoids the instant-equality trap, so an intake stored earlier
///    the same local day still matches. The DB unique key
///    `(medicationId, slotId, scheduledAt)` guarantees at most one intake per
///    occurrence.
/// 3. For each [DueDose], resolve its intake (else [IntakeStatus.pending]),
///    carry through its [TodayDose.confirmedAt], and compute
///    [TodayDose.windowState] (time-only, from [intakeWindow]),
///    [TodayDose.actionable] (from `windowState` + status + [allowMarkAhead]),
///    and [TodayDose.undoable] (from [gracePeriod]). All time math is UTC.
/// 4. Bucket the shaped doses by `slot.minuteOfDay ~/ 60` into
///    [TodayHourGroup]s — ascending by hour, preserving [expandDueDoses] order
///    within each group — deriving each group's [TodayGroupState] and
///    `takenCount`.
/// 5. Resolve [TodayView.nextIntake]: the earliest dose with
///    [DoseWindowState.future] and [IntakeStatus.pending] status (the first such
///    dose in ascending iteration order), or `null` when none exists.
///
/// Every due dose appears in the result regardless of whether its scheduled
/// time is past or future relative to [now].
TodayView buildTodayView({
  required List<Medication> meds,
  required List<Intake> intakes,
  required DateTime now,
  required IntakeWindow intakeWindow,
  required Duration gracePeriod,
  required bool allowMarkAhead,
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

  final List<TodayDose> shaped = <TodayDose>[
    for (final DueDose d in due)
      _shapeDose(
        d,
        byOccurrence,
        now,
        intakeWindow,
        gracePeriod,
        allowMarkAhead,
      ),
  ];

  final List<TodayHourGroup> groups = _bucketByHour(shaped);
  final TodayDose? nextIntake = _findNextIntake(groups);

  return TodayView(groups: groups, nextIntake: nextIntake);
}

/// Resolves a single [DueDose] against the pre-built [byOccurrence] index as of
/// [now], deriving its status, window classification, enablement, and undo
/// flag.
///
/// Looks up the matching intake by the record key
/// `(medication.id, slot.id, localCalendarDate(scheduledAt))` — an O(1)
/// operation. Returns a [TodayDose] whose status is [IntakeStatus.pending] when
/// no intake is indexed for that occurrence.
TodayDose _shapeDose(
  DueDose d,
  Map<(String, String, DateTime), Intake> byOccurrence,
  DateTime now,
  IntakeWindow intakeWindow,
  Duration gracePeriod,
  bool allowMarkAhead,
) {
  final Intake? matched =
      byOccurrence[(
        d.medication.id.value,
        d.slot.id.value,
        localCalendarDate(d.scheduledAt),
      )];
  final IntakeStatus status = matched?.status ?? IntakeStatus.pending;
  final DateTime? confirmedAt = matched?.confirmedAt;
  final DoseWindowState windowState = _classifyWindow(
    scheduledAt: d.scheduledAt,
    now: now,
    intakeWindow: intakeWindow,
  );

  return TodayDose(
    dose: d,
    status: status,
    confirmedAt: confirmedAt,
    windowState: windowState,
    actionable: _isActionable(
      status: status,
      windowState: windowState,
      allowMarkAhead: allowMarkAhead,
    ),
    undoable: _isUndoable(
      status: status,
      confirmedAt: confirmedAt,
      now: now,
      gracePeriod: gracePeriod,
    ),
    intakeId: matched?.id,
  );
}

/// Classifies a dose's [scheduledAt] against [now] and the [intakeWindow],
/// computed in **UTC**.
///
/// [DoseWindowState.future] when `now < scheduledAt`; [DoseWindowState.pastWindow]
/// when `now > scheduledAt + intakeWindow`; otherwise [DoseWindowState.open]
/// (inclusive of both `scheduledAt` and the window close).
DoseWindowState _classifyWindow({
  required DateTime scheduledAt,
  required DateTime now,
  required IntakeWindow intakeWindow,
}) {
  final DateTime nowUtc = now.toUtc();
  final DateTime open = scheduledAt.toUtc();
  final DateTime close = open.add(Duration(minutes: intakeWindow.minutes));
  if (nowUtc.isBefore(open)) {
    return DoseWindowState.future;
  }
  if (nowUtc.isAfter(close)) {
    return DoseWindowState.pastWindow;
  }
  return DoseWindowState.open;
}

/// Whether a dose with [status] in [windowState] is interactive now.
///
/// Only a [IntakeStatus.pending] dose can be actionable. For a pending dose:
/// [DoseWindowState.open] ⇒ `true`; [DoseWindowState.future] ⇒ [allowMarkAhead];
/// [DoseWindowState.pastWindow] ⇒ `false`.
bool _isActionable({
  required IntakeStatus status,
  required DoseWindowState windowState,
  required bool allowMarkAhead,
}) {
  if (status != IntakeStatus.pending) {
    return false;
  }
  switch (windowState) {
    case DoseWindowState.open:
      return true;
    case DoseWindowState.future:
      return allowMarkAhead;
    case DoseWindowState.pastWindow:
      return false;
  }
}

/// Whether a confirmation with [status] at [confirmedAt] may still be undone as
/// of [now]: non-pending, confirmed, and within [gracePeriod].
///
/// Compared in UTC. The boundary is inclusive (exactly the grace period is
/// still undoable); a future [confirmedAt] yields a negative elapsed span and is
/// never undoable.
bool _isUndoable({
  required IntakeStatus status,
  required DateTime? confirmedAt,
  required DateTime now,
  required Duration gracePeriod,
}) {
  if (status == IntakeStatus.pending || confirmedAt == null) {
    return false;
  }
  final Duration elapsed = now.toUtc().difference(confirmedAt.toUtc());
  return !elapsed.isNegative && elapsed <= gracePeriod;
}

/// Buckets the ordered [shaped] doses into [TodayHourGroup]s by wall-clock hour.
///
/// Groups are returned ascending by hour; within each group the doses keep the
/// ascending [expandDueDoses] order. Empty buckets are never emitted, so every
/// returned group holds at least one dose.
List<TodayHourGroup> _bucketByHour(List<TodayDose> shaped) {
  final Map<int, List<TodayDose>> byHour = <int, List<TodayDose>>{};
  for (final TodayDose d in shaped) {
    final int hour = d.dose.slot.minuteOfDay ~/ 60;
    (byHour[hour] ??= <TodayDose>[]).add(d);
  }

  final List<int> hours = byHour.keys.toList()..sort();
  return <TodayHourGroup>[
    for (final int hour in hours)
      _buildGroup(hour, byHour[hour] ?? const <TodayDose>[]),
  ];
}

/// Builds a single [TodayHourGroup] for [hour] from its non-empty [doses],
/// deriving the aggregate [TodayGroupState] and the `taken` count in one pass.
///
/// The group is [TodayGroupState.future] when every dose is
/// [DoseWindowState.future], [TodayGroupState.past] when every dose is
/// [DoseWindowState.pastWindow], and [TodayGroupState.now] otherwise (any open
/// dose, or a future/past mix).
TodayHourGroup _buildGroup(int hour, List<TodayDose> doses) {
  int takenCount = 0;
  bool allFuture = true;
  bool allPast = true;
  for (final TodayDose d in doses) {
    if (d.status == IntakeStatus.taken) {
      takenCount++;
    }
    switch (d.windowState) {
      case DoseWindowState.future:
        allPast = false;
      case DoseWindowState.open:
        allFuture = false;
        allPast = false;
      case DoseWindowState.pastWindow:
        allFuture = false;
    }
  }

  final TodayGroupState state;
  if (allFuture) {
    state = TodayGroupState.future;
  } else if (allPast) {
    state = TodayGroupState.past;
  } else {
    state = TodayGroupState.now;
  }

  return TodayHourGroup(
    hour: hour,
    doses: doses,
    state: state,
    takenCount: takenCount,
  );
}

/// Finds the countdown target across the hour-ordered [groups]: the first dose
/// (earliest by schedule time) with [DoseWindowState.future] and
/// [IntakeStatus.pending] status, or `null` when none exists.
///
/// Because [groups] are ascending by hour and each group's doses keep the
/// ascending [expandDueDoses] order, the first matching dose in iteration order
/// has the minimum scheduled instant among all future-pending doses.
TodayDose? _findNextIntake(List<TodayHourGroup> groups) {
  for (final TodayHourGroup g in groups) {
    for (final TodayDose d in g.doses) {
      if (d.windowState == DoseWindowState.future &&
          d.status == IntakeStatus.pending) {
        return d;
      }
    }
  }
  return null;
}
