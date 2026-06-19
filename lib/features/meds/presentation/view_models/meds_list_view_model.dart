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

import 'package:dosly/core/utils/fuzzy_name_match.dart';

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

/// Minimum [fuzzyNameScore] for a non-substring fuzzy match to be included in
/// search results.
///
/// Sits below the fuzzy band ceiling (`~0.85`) and well below the substring
/// bands (`>=0.9`), so any case-insensitive substring/prefix match always
/// clears it — the substring guarantee holds for free. Tuned against the debug
/// seed set (OQ-2) to admit one-character typos while dropping unrelated names.
const double medsSearchIncludeThreshold = 0.6;

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
/// 3. Apply [query]: when its trimmed form is non-empty, score each item with
///    [fuzzyNameScore] and keep those scoring `>= medsSearchIncludeThreshold`.
///    Because the scorer returns `>=0.9` for any case-insensitive substring or
///    prefix match, this preserves the substring guarantee while admitting
///    typo-tolerant fuzzy matches. Each kept item carries its score for
///    ranking. When the query is blank, every item is kept (no scoring).
/// 4. Apply [filter]: [MedsFilter.all] keeps everything; [MedsFilter.active]
///    drops items whose [activity] is [MedicationActivityStatus.completed].
/// 5. Group by [MedicationType] — continuous vs course. With an active query,
///    sort each group by descending match score, breaking ties by medication
///    name (ascending, case-insensitive). With a blank query, sort by name only
///    (ascending, case-insensitive).
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

  // 3. Fuzzy search (skipped when the query is blank). Each kept item is paired
  //    with its match score so step 5 can rank by relevance. Inclusion via
  //    `fuzzyNameScore >= medsSearchIncludeThreshold` subsumes the substring
  //    rule: substring/prefix matches always score >= 0.9, well above 0.6.
  final bool hasQuery = query.trim().isNotEmpty;
  final List<(double, MedListItem)> scored = <(double, MedListItem)>[];
  for (final MedListItem item in items) {
    if (!hasQuery) {
      scored.add((0.0, item));
      continue;
    }
    final double score = fuzzyNameScore(query, item.medication.name);
    if (score >= medsSearchIncludeThreshold) {
      scored.add((score, item));
    }
  }

  // 4. Active-only filter (drops completed courses), preserving scores.
  final Iterable<(double, MedListItem)> filtered = switch (filter) {
    MedsFilter.all => scored,
    MedsFilter.active => scored.where(
        ((double, MedListItem) entry) =>
            entry.$2.activity != MedicationActivityStatus.completed,
      ),
  };

  // 5. Group by temporal type, then sort each group: by descending score (ties
  //    broken by name) when a query is active, by name alone otherwise.
  final List<(double, MedListItem)> continuousScored = <(double, MedListItem)>[];
  final List<(double, MedListItem)> courseScored = <(double, MedListItem)>[];
  for (final (double, MedListItem) entry in filtered) {
    switch (entry.$2.medication.type) {
      case ContinuousType():
        continuousScored.add(entry);
      case CourseType():
        courseScored.add(entry);
    }
  }

  final int Function((double, MedListItem), (double, MedListItem)) comparator =
      hasQuery ? _byScoreThenName : _byScoredName;
  continuousScored.sort(comparator);
  courseScored.sort(comparator);

  return MedsListView(
    continuous: <MedListItem>[
      for (final (double, MedListItem) entry in continuousScored) entry.$2,
    ],
    course: <MedListItem>[
      for (final (double, MedListItem) entry in courseScored) entry.$2,
    ],
    totalCount: totalCount,
  );
}

/// Orders scored items by descending match score, breaking ties by name
/// (ascending, case-insensitive). Used while a search query is active.
int _byScoreThenName((double, MedListItem) a, (double, MedListItem) b) {
  final int byScore = b.$1.compareTo(a.$1);
  if (byScore != 0) {
    return byScore;
  }
  return _byNameCaseInsensitive(a.$2, b.$2);
}

/// Orders scored items by medication name alone (ascending, case-insensitive),
/// ignoring score. Used when no search query is active.
int _byScoredName((double, MedListItem) a, (double, MedListItem) b) =>
    _byNameCaseInsensitive(a.$2, b.$2);

/// Compares two items by medication name, ascending and case-insensitive.
int _byNameCaseInsensitive(MedListItem a, MedListItem b) =>
    a.medication.name.toLowerCase().compareTo(b.medication.name.toLowerCase());
