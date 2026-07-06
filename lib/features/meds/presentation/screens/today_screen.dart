/// Meds feature — reactive Today checklist screen for the dosly MVP.
///
/// This library hosts [TodayScreen], the screen displayed at the app's root
/// route (`/`) and surfaced in the bottom navigation as "Today". It combines
/// the live [medicationsListProvider] and [intakesListProvider] streams via
/// [buildTodayView] into the day's shaped [TodayView]: a [TodayCountdownCard]
/// for the next upcoming dose above the day's doses bucketed into
/// collapsible [TodayGroupSection]s (one per wall-clock hour). Each section's
/// dose tiles wire their checkbox/skip/undo affordances to
/// [markIntakeTakenProvider], [skipIntakeProvider], and [undoIntakeProvider]
/// respectively, and a group's Mark-all button confirms every actionable
/// pending dose in that group. It lives in `meds/presentation/` (not `home/`)
/// because it depends directly on `meds`-feature providers, view models, and
/// widgets (constitution §2.1 — presentation code that imports another
/// feature's presentation layer must live inside that feature).
library;

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../settings/domain/value_objects/grace_period.dart';
import '../../../settings/domain/value_objects/intake_window.dart';
import '../../domain/entities/intake.dart';
import '../../domain/entities/intake_status.dart';
import '../../domain/entities/medication.dart';
import '../providers/intake_providers.dart';
import '../providers/medication_providers.dart';
import '../view_models/today_view_model.dart';
import '../widgets/today_countdown_card.dart';
import '../widgets/today_empty_state.dart';
import '../widgets/today_group_section.dart';

/// Reactive Today checklist screen shown at the app's root route.
///
/// Displays a Material 3 [AppBar] with the localized title
/// (`context.l10n.todayTitle`), a settings-gear [IconButton] action that
/// pushes `/settings`, and a 1-px bottom [Divider] — matching the chrome of
/// the retired placeholder `HomeScreen` and the sibling [MedsScreen] AppBar.
/// Below the app bar a muted date header shows today's date via
/// [MaterialLocalizations.formatFullDate].
///
/// The body watches [medicationsListProvider], [intakesListProvider] (both
/// `AsyncValue`), and [todayIntakeSettingsProvider]: either loading → a
/// centered [CircularProgressIndicator]; either error → a centered muted
/// error message; otherwise the doses due today are shaped via
/// [buildTodayView] and rendered as [TodayEmptyState] (nothing due) or a
/// scrollable list whose first item is the [TodayCountdownCard] (the next
/// upcoming dose, or "all done") followed by one [TodayGroupSection] per
/// [TodayView.groups]. The group whose [TodayHourGroup.state] is
/// [TodayGroupState.now] starts expanded; when no group is currently "now",
/// the soonest [TodayGroupState.future] group starts expanded instead; every
/// other group starts collapsed (and, when neither exists, none start
/// expanded).
///
/// Each dose's checkbox/skip/undo affordance calls the corresponding intake
/// use case ([markIntakeTakenProvider] / [skipIntakeProvider] /
/// [undoIntakeProvider]); a failed call shows a localized error [SnackBar]. A
/// group's Mark-all button confirms every actionable pending dose in that
/// group sequentially via [_onMarkAllInGroup]. The reactive streams pick up
/// each change automatically, so no manual refresh is needed on success.
///
/// A single rescheduling ONE-SHOT [Timer] (never [Timer.periodic] — that
/// breaks `pumpAndSettle` in widget tests) re-triggers a rebuild exactly at
/// the next relevant BOUNDARY instant — a future dose's window opening, an
/// open dose's window closing, or a taken/skipped dose's grace period
/// expiring — so the countdown, group badges, per-dose enablement, and the
/// Undo affordance all re-derive live without polling (constitution §5.2).
/// Firing the timer only calls `setState` to re-derive the already-loaded
/// [TodayView] on the next [build]: it performs NO database writes and
/// triggers NO reconciliation, so it can never loop or duplicate data. It is
/// cancelled in [dispose] and whenever it is rescheduled.
class TodayScreen extends ConsumerStatefulWidget {
  /// Creates the Today checklist screen.
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// The pending boundary-refresh timer, if any. `null` when no future
  /// boundary instant exists among the currently rendered doses. Always
  /// cancelled before being replaced or cleared, so at most one timer is ever
  /// pending.
  Timer? _boundaryTimer;

  /// Fires the auto-miss reconciliation ([ReconcileMissedIntakes]) once, as
  /// soon as the Today screen is opened.
  ///
  /// `initState` runs exactly ONCE per mount — never on a rebuild — so this
  /// is "once per Today load", not "once per rebuild": there is NO
  /// reconcile↔rebuild loop. Any `missed` rows the reconciliation writes are
  /// picked up by the reactive [intakesListProvider] stream, which re-emits
  /// and drives [build] directly; that rebuild never re-enters `initState`.
  /// Scheduled via [Future.microtask] so it never blocks the first frame, and
  /// fire-and-forget: [ReconcileMissedIntakes.call] returns a `Left` as a
  /// VALUE on failure (it never throws), so there is no unhandled error to
  /// guard against. The `mounted` guard only covers the case where the widget
  /// is disposed before the scheduled microtask runs.
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(reconcileMissedIntakesProvider).call(now: clock.now());
    });
  }

  @override
  void dispose() {
    _boundaryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime now = clock.now();
    final AsyncValue<List<Medication>> medsAsync = ref.watch(
      medicationsListProvider,
    );
    final AsyncValue<List<Intake>> intakesAsync = ref.watch(
      intakesListProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.todayTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            tooltip: l10n.settingsTooltip,
            icon: const Icon(LucideIcons.settings),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              MaterialLocalizations.of(context).formatFullDate(now),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: _buildBody(context, medsAsync, intakesAsync, now, l10n),
          ),
        ],
      ),
    );
  }

  /// Combines [medsAsync] and [intakesAsync] into the body widget: loading,
  /// error, empty, or the countdown-card-plus-groups list.
  ///
  /// Also owns the boundary-refresh timer's lifecycle: it is cancelled
  /// whenever the screen is not showing a settled [TodayView] and
  /// (re)scheduled from the freshly computed [TodayView] on every successful
  /// build.
  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<Medication>> medsAsync,
    AsyncValue<List<Intake>> intakesAsync,
    DateTime now,
    AppLocalizations l10n,
  ) {
    // Reactive (AC-8): watched, not read, so a Settings edit to the intake
    // window / grace / mark-ahead re-derives the checklist live.
    final settings = ref.watch(todayIntakeSettingsProvider);

    if (medsAsync.isLoading || intakesAsync.isLoading) {
      _cancelBoundaryTimer();
      return const Center(child: CircularProgressIndicator());
    }

    if (medsAsync.hasError || intakesAsync.hasError) {
      _cancelBoundaryTimer();
      final ColorScheme cs = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.todayLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final List<Medication> meds = medsAsync.value ?? const <Medication>[];
    final List<Intake> intakes = intakesAsync.value ?? const <Intake>[];
    final TodayView view = buildTodayView(
      meds: meds,
      intakes: intakes,
      now: now,
      intakeWindow: settings.intakeWindow,
      gracePeriod: Duration(minutes: settings.gracePeriod.minutes),
      allowMarkAhead: settings.allowMarkAhead,
    );
    _scheduleNextBoundaryRefresh(view, now, settings);

    if (view.isEmpty) {
      return const TodayEmptyState();
    }

    // AC-3: the "now" group (if any) starts expanded; otherwise the soonest
    // future group starts expanded and every other group starts collapsed.
    final bool anyNow = view.groups.any(
      (TodayHourGroup g) => g.state == TodayGroupState.now,
    );
    int? soonestFutureHour;
    if (!anyNow) {
      for (final TodayHourGroup g in view.groups) {
        if (g.state == TodayGroupState.future) {
          soonestFutureHour = g.hour;
          break;
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: view.groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TodayCountdownCard(
              nextScheduledAt: view.nextIntake?.dose.scheduledAt,
              now: now,
            ),
          );
        }

        final TodayHourGroup group = view.groups[index - 1];
        final bool initiallyExpanded = anyNow
            ? group.state == TodayGroupState.now
            : group.hour == soonestFutureHour;

        return TodayGroupSection(
          // Note: 'todayGroupSection-${hour}' (without the "Item" suffix) is
          // already used internally by TodayGroupSection's own root Container
          // (see today_group_section.dart) and is targeted by this screen's
          // existing tests via `_groupSectionKey`. A distinct suffix avoids
          // colliding with that key while still giving each list item a
          // stable per-group identity across boundary-timer rebuilds.
          key: ValueKey<String>('todayGroupSectionItem-${group.hour}'),
          group: group,
          initiallyExpanded: initiallyExpanded,
          now: now,
          onTaken: _onTaken,
          onSkip: _onSkip,
          onUndo: _onUndo,
          onMarkAll: () => _onMarkAllInGroup(group),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Boundary-refresh timer
  // ---------------------------------------------------------------------

  /// Cancels any previously scheduled boundary-refresh timer and, if [view]
  /// has at least one relevant instant strictly after [now], schedules a
  /// single one-shot [Timer] firing exactly at the MINIMUM such instant.
  /// Schedules no timer when no such instant exists.
  ///
  /// The candidate boundary instants (computed in UTC, using [settings]) are
  /// gathered across every dose in every group:
  /// * [DoseWindowState.future] — the scheduled instant (the window opens).
  /// * [DoseWindowState.open] — the scheduled instant plus
  ///   [IntakeWindow.minutes] (the window closes).
  /// * a still-[TodayDose.undoable] confirmed dose — [TodayDose.confirmedAt]
  ///   plus [GracePeriod.minutes] (the undo grace expires).
  ///
  /// Only candidates STRICTLY AFTER [now] are considered (a candidate at or
  /// before `now` would schedule a zero/negative-duration [Timer] that could
  /// re-fire and re-schedule itself in a tight loop, hanging
  /// `pumpAndSettle`). Firing the timer only `setState`s to re-derive the
  /// already-loaded [TodayView] on the next [build] — it performs NO database
  /// writes and triggers NO reconciliation.
  void _scheduleNextBoundaryRefresh(
    TodayView view,
    DateTime now,
    ({IntakeWindow intakeWindow, GracePeriod gracePeriod, bool allowMarkAhead})
    settings,
  ) {
    _cancelBoundaryTimer();

    final DateTime nowUtc = now.toUtc();
    DateTime? minBoundary;

    void consider(DateTime candidate) {
      final DateTime c = candidate.toUtc();
      if (!c.isAfter(nowUtc)) {
        return;
      }
      final DateTime? currentMin = minBoundary;
      if (currentMin == null || c.isBefore(currentMin)) {
        minBoundary = c;
      }
    }

    for (final TodayHourGroup group in view.groups) {
      for (final TodayDose dose in group.doses) {
        switch (dose.windowState) {
          case DoseWindowState.future:
            consider(dose.dose.scheduledAt);
          case DoseWindowState.open:
            consider(
              dose.dose.scheduledAt.toUtc().add(
                Duration(minutes: settings.intakeWindow.minutes),
              ),
            );
          case DoseWindowState.pastWindow:
            break;
        }

        final DateTime? confirmedAt = dose.confirmedAt;
        if (dose.undoable && confirmedAt != null) {
          consider(
            confirmedAt.toUtc().add(
              Duration(minutes: settings.gracePeriod.minutes),
            ),
          );
        }
      }
    }

    final DateTime? boundary = minBoundary;
    if (boundary == null) {
      return;
    }

    _boundaryTimer = Timer(boundary.difference(nowUtc), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Cancels the pending boundary-refresh timer, if any.
  void _cancelBoundaryTimer() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  /// Confirms [dose] as taken via [markIntakeTakenProvider].
  ///
  /// Captures [ScaffoldMessenger] and l10n before the `await` and guards with
  /// `mounted` afterwards (`use_build_context_synchronously`). On failure
  /// shows a localized error [SnackBar]; on success shows nothing — the
  /// reactive streams update the checklist automatically.
  Future<void> _onTaken(TodayDose dose) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = context.l10n;

    final result = await ref
        .read(markIntakeTakenProvider)
        .call(
          medicationId: dose.dose.medication.id,
          slotId: dose.dose.slot.id,
          scheduledAt: dose.dose.scheduledAt,
          now: clock.now(),
        );

    if (!mounted) return;
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.todayActionError)),
      ),
      (_) {},
    );
  }

  /// Records [dose] as skipped via [skipIntakeProvider].
  ///
  /// Mirrors [_onTaken]'s async-safety idiom and error handling.
  Future<void> _onSkip(TodayDose dose) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = context.l10n;

    final result = await ref
        .read(skipIntakeProvider)
        .call(
          medicationId: dose.dose.medication.id,
          slotId: dose.dose.slot.id,
          scheduledAt: dose.dose.scheduledAt,
          now: clock.now(),
        );

    if (!mounted) return;
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.todayActionError)),
      ),
      (_) {},
    );
  }

  /// Reverts [dose]'s confirmation via [undoIntakeProvider], within its
  /// grace window.
  ///
  /// A no-op when [dose] has no matched intake id or confirmation timestamp
  /// (never undoable in that state — defensive guard mirroring
  /// [TodayDose.undoable]). Mirrors [_onTaken]'s async-safety idiom.
  Future<void> _onUndo(TodayDose dose) async {
    final intakeId = dose.intakeId;
    final confirmedAt = dose.confirmedAt;
    if (intakeId == null || confirmedAt == null) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = context.l10n;

    final result = await ref
        .read(undoIntakeProvider)
        .call(
          id: intakeId,
          confirmedAt: confirmedAt,
          now: clock.now(),
          gracePeriod: Duration(
            minutes: ref.read(todayIntakeSettingsProvider).gracePeriod.minutes,
          ),
        );

    if (!mounted) return;
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.todayActionError)),
      ),
      (_) {},
    );
  }

  /// Confirms every actionable pending dose in [group] as taken, sequentially.
  ///
  /// Iterates [TodayHourGroup.doses] filtered to
  /// `status == IntakeStatus.pending && actionable`, `await`ing
  /// [markIntakeTakenProvider] for each ONE AT A TIME (never in parallel) so
  /// the writes apply in a stable, predictable order. Captures
  /// [ScaffoldMessenger] and l10n once, before the loop; shows at most ONE
  /// localized error [SnackBar] if any call fails, after the whole loop
  /// completes. Each iteration re-checks `mounted` BEFORE reading
  /// [markIntakeTakenProvider] — `ref.read` throws on a disposed element, and
  /// the previous iteration's `await` is a suspension point where the user
  /// could navigate away, so the guard must be per-iteration, not just once
  /// after the loop.
  Future<void> _onMarkAllInGroup(TodayHourGroup group) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = context.l10n;
    bool anyFailed = false;

    final Iterable<TodayDose> actionablePending = group.doses.where(
      (TodayDose d) => d.status == IntakeStatus.pending && d.actionable,
    );
    for (final TodayDose dose in actionablePending) {
      if (!mounted) return;
      final result = await ref
          .read(markIntakeTakenProvider)
          .call(
            medicationId: dose.dose.medication.id,
            slotId: dose.dose.slot.id,
            scheduledAt: dose.dose.scheduledAt,
            now: clock.now(),
          );
      result.fold((_) => anyFailed = true, (_) {});
    }

    if (!mounted) return;
    if (anyFailed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.todayActionError)));
    }
  }
}
