/// Tests for [buildMedsListView] — the pure shaping function that turns a raw
/// medication list into the rendered meds-list structure.
///
/// Covers, with an explicit injected `now` (never the wall clock):
///   - grouping + sort: mixed continuous/course meds land in the right list,
///     each sorted case-insensitively by name.
///   - filter: [MedsFilter.active] hides a completed non-cyclic course but keeps
///     continuous meds and cyclic courses; [MedsFilter.all] includes the
///     completed one.
///   - search: a case-insensitive substring filters across BOTH sections; an
///     empty query applies no filtering.
///   - totalCount: reflects the pre-filter/pre-search input length.
///   - per-item derivation: a [CourseType] item carries non-null [CourseProgress]
///     with the expected currentDay; a [ContinuousType] item has null progress.
///   - empty input: empty groups and totalCount == 0.
library;

import 'package:dosly/features/meds/domain/entities/course_phase.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_activity_status.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/view_models/meds_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A fixed "current instant" used by every test so derivations are deterministic.
final DateTime _now = DateTime.utc(2026, 6, 18, 9, 0);

/// Minimal valid daily schedule shared by all fixtures (slot ids stay distinct
/// across fixtures to mirror real data, though the shaping function ignores
/// them).
Schedule _schedule(String slotId) => Schedule(
      frequency: ScheduleFrequency.daily,
      slots: <TimeSlot>[
        TimeSlot(id: TimeSlotId(slotId), minuteOfDay: 480),
      ],
    );

/// Builds a continuous medication with the given [id], [name] and [startDate].
Medication _continuous({
  required String id,
  required String name,
  required DateTime startDate,
}) =>
    Medication(
      id: MedicationId(id),
      name: name,
      form: MedicationForm.tablet,
      type: MedicationType.continuous(startDate: startDate),
      schedule: _schedule('$id-slot'),
      dosePerIntake: null,
      stock: null,
      notes: null,
      createdAt: DateTime.utc(2026, 1, 1),
    );

/// Builds a course medication with the given timing.
Medication _course({
  required String id,
  required String name,
  required DateTime startDate,
  required int durationDays,
  required int pauseDays,
}) =>
    Medication(
      id: MedicationId(id),
      name: name,
      form: MedicationForm.capsule,
      type: MedicationType.course(
        startDate: startDate,
        durationDays: durationDays,
        pauseDays: pauseDays,
      ),
      schedule: _schedule('$id-slot'),
      dosePerIntake: null,
      stock: null,
      notes: null,
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  group('buildMedsListView', () {
    // -----------------------------------------------------------------------
    // Grouping + sort
    // -----------------------------------------------------------------------
    group('grouping and sort', () {
      test('splits continuous and course meds into separate groups', () {
        final List<Medication> meds = <Medication>[
          _continuous(
            id: 'c1',
            name: 'Aspirin',
            startDate: DateTime.utc(2026, 1, 1),
          ),
          _course(
            id: 'k1',
            name: 'Amoxicillin',
            startDate: DateTime.utc(2026, 6, 17),
            durationDays: 7,
            pauseDays: 0,
          ),
        ];

        final MedsListView view = buildMedsListView(
          meds: meds,
          now: _now,
          filter: MedsFilter.all,
          query: '',
        );

        expect(view.continuous.length, 1);
        expect(view.continuous.single.medication.name, 'Aspirin');
        expect(view.course.length, 1);
        expect(view.course.single.medication.name, 'Amoxicillin');
      });

      test('sorts each group by name case-insensitively ascending', () {
        final List<Medication> meds = <Medication>[
          _continuous(
            id: 'c1',
            name: 'zinc',
            startDate: DateTime.utc(2026, 1, 1),
          ),
          _continuous(
            id: 'c2',
            name: 'Aspirin',
            startDate: DateTime.utc(2026, 1, 1),
          ),
          _continuous(
            id: 'c3',
            name: 'biotin',
            startDate: DateTime.utc(2026, 1, 1),
          ),
          _course(
            id: 'k1',
            name: 'Vitamin D',
            startDate: DateTime.utc(2026, 6, 17),
            durationDays: 30,
            pauseDays: 0,
          ),
          _course(
            id: 'k2',
            name: 'amoxicillin',
            startDate: DateTime.utc(2026, 6, 17),
            durationDays: 7,
            pauseDays: 0,
          ),
        ];

        final MedsListView view = buildMedsListView(
          meds: meds,
          now: _now,
          filter: MedsFilter.all,
          query: '',
        );

        expect(
          view.continuous.map((MedListItem i) => i.medication.name).toList(),
          <String>['Aspirin', 'biotin', 'zinc'],
        );
        expect(
          view.course.map((MedListItem i) => i.medication.name).toList(),
          <String>['amoxicillin', 'Vitamin D'],
        );
      });
    });

    // -----------------------------------------------------------------------
    // Filter
    // -----------------------------------------------------------------------
    group('MedsFilter', () {
      // A non-cyclic course that started far in the past with a short duration:
      // completed as of _now. Started 2026-01-01, 5-day course -> last active
      // day 2026-01-05, long completed by 2026-06-18.
      Medication completedCourse() => _course(
            id: 'done',
            name: 'Old Course',
            startDate: DateTime.utc(2026, 1, 1),
            durationDays: 5,
            pauseDays: 0,
          );

      // A cyclic course (pauseDays > 0) never completes regardless of age.
      Medication cyclicCourse() => _course(
            id: 'cyc',
            name: 'Cyclic Course',
            startDate: DateTime.utc(2026, 1, 1),
            durationDays: 7,
            pauseDays: 7,
          );

      Medication continuousMed() => _continuous(
            id: 'cont',
            name: 'Continuous Med',
            startDate: DateTime.utc(2026, 1, 1),
          );

      test('active drops the completed non-cyclic course', () {
        final MedsListView view = buildMedsListView(
          meds: <Medication>[
            completedCourse(),
            cyclicCourse(),
            continuousMed(),
          ],
          now: _now,
          filter: MedsFilter.active,
          query: '',
        );

        final List<String> courseNames =
            view.course.map((MedListItem i) => i.medication.name).toList();
        expect(courseNames, isNot(contains('Old Course')));
      });

      test('active keeps the continuous med and the cyclic course', () {
        final MedsListView view = buildMedsListView(
          meds: <Medication>[
            completedCourse(),
            cyclicCourse(),
            continuousMed(),
          ],
          now: _now,
          filter: MedsFilter.active,
          query: '',
        );

        expect(
          view.continuous.map((MedListItem i) => i.medication.name).toList(),
          <String>['Continuous Med'],
        );
        expect(
          view.course.map((MedListItem i) => i.medication.name).toList(),
          <String>['Cyclic Course'],
        );
      });

      test('all includes the completed course', () {
        final MedsListView view = buildMedsListView(
          meds: <Medication>[
            completedCourse(),
            cyclicCourse(),
            continuousMed(),
          ],
          now: _now,
          filter: MedsFilter.all,
          query: '',
        );

        final List<String> courseNames =
            view.course.map((MedListItem i) => i.medication.name).toList();
        expect(courseNames, containsAll(<String>['Old Course', 'Cyclic Course']));

        // Sanity: the completed item is indeed marked completed.
        final MedListItem completed = view.course.firstWhere(
          (MedListItem i) => i.medication.name == 'Old Course',
        );
        expect(completed.activity, MedicationActivityStatus.completed);
      });
    });

    // -----------------------------------------------------------------------
    // Search
    // -----------------------------------------------------------------------
    group('search query', () {
      List<Medication> searchFixture() => <Medication>[
            _continuous(
              id: 'c1',
              name: 'Vitamin C',
              startDate: DateTime.utc(2026, 1, 1),
            ),
            _continuous(
              id: 'c2',
              name: 'Aspirin',
              startDate: DateTime.utc(2026, 1, 1),
            ),
            _course(
              id: 'k1',
              name: 'Vitamin D Course',
              startDate: DateTime.utc(2026, 6, 17),
              durationDays: 30,
              pauseDays: 0,
            ),
          ];

      test('case-insensitive substring filters across both sections', () {
        final MedsListView view = buildMedsListView(
          meds: searchFixture(),
          now: _now,
          filter: MedsFilter.all,
          query: 'vitamin',
        );

        expect(
          view.continuous.map((MedListItem i) => i.medication.name).toList(),
          <String>['Vitamin C'],
        );
        expect(
          view.course.map((MedListItem i) => i.medication.name).toList(),
          <String>['Vitamin D Course'],
        );
      });

      test('empty query applies no filtering', () {
        final MedsListView view = buildMedsListView(
          meds: searchFixture(),
          now: _now,
          filter: MedsFilter.all,
          query: '',
        );

        expect(view.continuous.length, 2);
        expect(view.course.length, 1);
      });

      test('whitespace-only query is treated as empty (no filtering)', () {
        final MedsListView view = buildMedsListView(
          meds: searchFixture(),
          now: _now,
          filter: MedsFilter.all,
          query: '   ',
        );

        expect(view.continuous.length, 2);
        expect(view.course.length, 1);
      });
    });

    // -----------------------------------------------------------------------
    // totalCount
    // -----------------------------------------------------------------------
    group('totalCount', () {
      test('reflects pre-filter/pre-search input length', () {
        final List<Medication> meds = <Medication>[
          _continuous(
            id: 'c1',
            name: 'Aspirin',
            startDate: DateTime.utc(2026, 1, 1),
          ),
          _continuous(
            id: 'c2',
            name: 'Ibuprofen',
            startDate: DateTime.utc(2026, 1, 1),
          ),
          _course(
            id: 'k1',
            name: 'Old Course',
            startDate: DateTime.utc(2026, 1, 1),
            durationDays: 3,
            pauseDays: 0,
          ),
        ];

        final MedsListView view = buildMedsListView(
          meds: meds,
          now: _now,
          // A filter + query that shrink the visible set.
          filter: MedsFilter.active,
          query: 'aspirin',
        );

        // Only Aspirin survives filter+search...
        expect(view.continuous.length, 1);
        expect(view.course, isEmpty);
        // ...but totalCount counts every input medication.
        expect(view.totalCount, meds.length);
        expect(view.totalCount, 3);
      });
    });

    // -----------------------------------------------------------------------
    // Per-item derivation
    // -----------------------------------------------------------------------
    group('per-item derivation', () {
      test('course item has non-null progress with expected currentDay', () {
        // Started 2026-06-15, 30-day course, now 2026-06-18 -> day 4 (1-based).
        final Medication med = _course(
          id: 'k1',
          name: 'Course Med',
          startDate: DateTime.utc(2026, 6, 15),
          durationDays: 30,
          pauseDays: 0,
        );

        final MedsListView view = buildMedsListView(
          meds: <Medication>[med],
          now: _now,
          filter: MedsFilter.all,
          query: '',
        );

        final MedListItem item = view.course.single;
        expect(item.progress, isNotNull);
        expect(item.progress?.currentDay, 4);
        expect(item.progress?.totalDays, 30);
        expect(item.progress?.phase, CoursePhase.activeWindow);
        expect(item.activity, MedicationActivityStatus.active);
      });

      test('continuous item has null progress and is active', () {
        final Medication med = _continuous(
          id: 'c1',
          name: 'Continuous Med',
          startDate: DateTime.utc(2026, 1, 1),
        );

        final MedsListView view = buildMedsListView(
          meds: <Medication>[med],
          now: _now,
          filter: MedsFilter.all,
          query: '',
        );

        final MedListItem item = view.continuous.single;
        expect(item.progress, isNull);
        expect(item.activity, MedicationActivityStatus.active);
      });
    });

    // -----------------------------------------------------------------------
    // Empty input
    // -----------------------------------------------------------------------
    test('empty input yields empty groups and totalCount 0', () {
      final MedsListView view = buildMedsListView(
        meds: const <Medication>[],
        now: _now,
        filter: MedsFilter.all,
        query: '',
      );

      expect(view.continuous, isEmpty);
      expect(view.course, isEmpty);
      expect(view.totalCount, 0);
    });
  });
}
