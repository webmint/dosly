/// Pure shaping of the raw medication list into the structure rendered by the
/// meds-list screen: per-item derived activity/progress, type-based grouping,
/// case-insensitive search, active-only filtering, and stable name sorting.
///
/// This is a `presentation/` view model. It depends only on the medication
/// `domain/` (entities, value objects, derivations) — never on Flutter, drift,
/// or the data layer. [buildMedsListView] is pure and synchronous: it takes an
/// explicit [DateTime] `now` (injected by the screen via `clock.now()`) rather
/// than reading the wall clock itself, so it is unit-testable without pumping
/// widgets or freezing time globally.
library;

import '../../domain/entities/medication.dart';
import '../../domain/entities/medication_activity_status.dart';
import '../../domain/entities/medication_type.dart';
import '../../domain/value_objects/course_progress.dart';
import '../../domain/value_objects/medication_activity.dart';

/// Which subset of medications the list should show.
///
/// Drives the active/all toggle on the meds-list screen.
enum MedsFilter {
  /// Show every medication, including completed (finished) courses.
  all,

  /// Show only medications whose derived activity is
  /// [MedicationActivityStatus.active], hiding completed courses.
  active,
}

/// A single medication ready for rendering, with its derived state attached.
///
/// Pairs the source [medication] with the values derived from it as of a given
/// instant: its [activity] (active vs completed) and, for [CourseType]
/// medications only, its cycle-day [progress]. [progress] is `null` for
/// continuous medications, which have no bounded course to track.
///
/// Immutable: constructed once by [buildMedsListView] and never mutated.
class MedListItem {
  /// Creates a [MedListItem] pairing [medication] with its derived state.
  const MedListItem({
    required this.medication,
    required this.activity,
    required this.progress,
  });

  /// The source medication this item renders.
  final Medication medication;

  /// The medication's derived active/completed status as of the build instant.
  final MedicationActivityStatus activity;

  /// Cycle-day progress for [CourseType] medications; `null` for continuous
  /// medications (which have no bounded course window).
  final CourseProgress? progress;
}

/// The fully-shaped data backing the meds-list screen.
///
/// Holds the two type-grouped, name-sorted, already-filtered/searched item
/// lists ([continuous] and [course]) plus [totalCount] — the number of input
/// medications BEFORE any filtering or search, used to distinguish a
/// "no medications at all" empty state from a "no matches" empty state.
///
/// Immutable: produced once per build by [buildMedsListView].
class MedsListView {
  /// Creates a [MedsListView] from its grouped lists and pre-filter count.
  const MedsListView({
    required this.continuous,
    required this.course,
    required this.totalCount,
  });

  /// Continuous medications ([ContinuousType]), sorted by name ascending
  /// (case-insensitive), after filter and search are applied.
  final List<MedListItem> continuous;

  /// Course medications ([CourseType]), sorted by name ascending
  /// (case-insensitive), after filter and search are applied.
  final List<MedListItem> course;

  /// Count of ALL input medications before filter/search — drives the
  /// "no medications at all" empty state.
  final int totalCount;
}

/// Shapes [meds] into a [MedsListView] for rendering as of [now].
///
/// Pure and synchronous. The pipeline is:
///
/// 1. Map each medication to a [MedListItem], deriving its [activity] via
///    `resolveMedicationActivity` and, for [CourseType] medications, its
///    [CourseProgress] via `CourseProgress.resolve` ([progress] is `null` for
///    continuous medications).
/// 2. Record [MedsListView.totalCount] as the input length, BEFORE any
///    filtering or search.
/// 3. Apply [query]: when its trimmed form is non-empty, keep only items whose
///    medication name contains the query as a case-insensitive substring.
/// 4. Apply [filter]: [MedsFilter.all] keeps everything; [MedsFilter.active]
///    drops items whose [activity] is [MedicationActivityStatus.completed].
/// 5. Group by [MedicationType] — continuous vs course — and sort each group by
///    medication name, ascending and case-insensitive.
MedsListView buildMedsListView({
  required List<Medication> meds,
  required DateTime now,
  required MedsFilter filter,
  required String query,
}) {
  final int totalCount = meds.length;

  // 1. Derive per-item activity and (course-only) progress.
  final List<MedListItem> items = meds.map((Medication med) {
    final MedicationActivityStatus activity = resolveMedicationActivity(
      med,
      now,
    );
    final CourseProgress? progress = switch (med.type) {
      final CourseType course =>
        CourseProgress.resolve(course: course, now: now),
      ContinuousType() => null,
    };
    return MedListItem(
      medication: med,
      activity: activity,
      progress: progress,
    );
  }).toList();

  // 3. Case-insensitive substring search (skipped when the query is blank).
  final String normalizedQuery = query.trim().toLowerCase();
  final Iterable<MedListItem> searched = normalizedQuery.isEmpty
      ? items
      : items.where(
          (MedListItem item) =>
              item.medication.name.toLowerCase().contains(normalizedQuery),
        );

  // 4. Active-only filter (drops completed courses).
  final Iterable<MedListItem> filtered = switch (filter) {
    MedsFilter.all => searched,
    MedsFilter.active => searched.where(
        (MedListItem item) =>
            item.activity != MedicationActivityStatus.completed,
      ),
  };

  // 5. Group by temporal type, then sort each group by name (case-insensitive).
  final List<MedListItem> continuous = <MedListItem>[];
  final List<MedListItem> course = <MedListItem>[];
  for (final MedListItem item in filtered) {
    switch (item.medication.type) {
      case ContinuousType():
        continuous.add(item);
      case CourseType():
        course.add(item);
    }
  }
  continuous.sort(_byNameCaseInsensitive);
  course.sort(_byNameCaseInsensitive);

  return MedsListView(
    continuous: continuous,
    course: course,
    totalCount: totalCount,
  );
}

/// Compares two items by medication name, ascending and case-insensitive.
int _byNameCaseInsensitive(MedListItem a, MedListItem b) =>
    a.medication.name.toLowerCase().compareTo(b.medication.name.toLowerCase());
