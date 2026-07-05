/// Meds feature — reactive Today checklist screen for the dosly MVP.
///
/// This library hosts [TodayScreen], the screen displayed at the app's root
/// route (`/`) and surfaced in the bottom navigation as "Today". It combines
/// the live [medicationsListProvider] and [intakesListProvider] streams via
/// [buildTodayView] into the day's ordered dose checklist, and wires each
/// [TodayDoseTile]'s Take/Skip/Undo affordances to [markIntakeTakenProvider],
/// [skipIntakeProvider], and [undoIntakeProvider] respectively. It lives in
/// `meds/presentation/` (not `home/`) because it depends directly on
/// `meds`-feature providers, view models, and widgets (constitution §2.1 —
/// presentation code that imports another feature's presentation layer must
/// live inside that feature).
library;

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/entities/intake.dart';
import '../../domain/entities/medication.dart';
import '../../domain/value_objects/intake_grace.dart';
import '../providers/intake_providers.dart';
import '../providers/medication_providers.dart';
import '../view_models/today_view_model.dart';
import '../widgets/today_dose_tile.dart';
import '../widgets/today_empty_state.dart';

/// Reactive Today checklist screen shown at the app's root route.
///
/// Displays a Material 3 [AppBar] with the localized title
/// (`context.l10n.todayTitle`), a settings-gear [IconButton] action that
/// pushes `/settings`, and a 1-px bottom [Divider] — matching the chrome of
/// the retired placeholder `HomeScreen` and the sibling [MedsScreen] AppBar.
/// Below the app bar a muted date header shows today's date via
/// [MaterialLocalizations.formatFullDate].
///
/// The body watches [medicationsListProvider] and [intakesListProvider]
/// (both `AsyncValue`) and combines them: either loading → a centered
/// [CircularProgressIndicator]; either error → a centered muted error
/// message; otherwise the doses due today are shaped via [buildTodayView] and
/// rendered as [TodayEmptyState] (nothing due) or a [ListView] of
/// [TodayDoseTile]s in ascending schedule-time order.
///
/// Each tile's Take/Skip/Undo affordance calls the corresponding intake use
/// case ([markIntakeTakenProvider] / [skipIntakeProvider] /
/// [undoIntakeProvider]); a failed call shows a localized error [SnackBar].
/// The reactive streams pick up the change automatically, so no manual
/// refresh is needed on success.
///
/// A single rescheduling ONE-SHOT [Timer] (never [Timer.periodic] — that
/// breaks `pumpAndSettle` in widget tests) re-triggers a rebuild exactly when
/// the soonest undoable dose's grace window elapses, so the Undo affordance
/// disappears on time without polling (constitution §5.2). The timer is
/// cancelled in [dispose] and whenever it is rescheduled.
class TodayScreen extends ConsumerStatefulWidget {
  /// Creates the Today checklist screen.
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// The pending grace-refresh timer, if any. `null` when no currently
  /// rendered dose is undoable. Always cancelled before being replaced or
  /// cleared, so at most one timer is ever pending.
  Timer? _graceTimer;

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
    _graceTimer?.cancel();
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
  /// error, empty, or the doses [ListView].
  ///
  /// Also owns the grace-refresh timer's lifecycle: it is cancelled whenever
  /// the screen is not showing a settled [TodayView] and (re)scheduled from
  /// the freshly computed [TodayView] on every successful build.
  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<Medication>> medsAsync,
    AsyncValue<List<Intake>> intakesAsync,
    DateTime now,
    AppLocalizations l10n,
  ) {
    if (medsAsync.isLoading || intakesAsync.isLoading) {
      _cancelGraceTimer();
      return const Center(child: CircularProgressIndicator());
    }

    if (medsAsync.hasError || intakesAsync.hasError) {
      _cancelGraceTimer();
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
    );
    _scheduleGraceRefresh(view, now);

    if (view.isEmpty) {
      return const TodayEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: view.doses.length,
      itemBuilder: (context, index) {
        final TodayDose dose = view.doses[index];
        return TodayDoseTile(
          key: ValueKey<String>(
            'todayTile-${dose.dose.medication.id.value}-${dose.dose.slot.id.value}',
          ),
          dose: dose,
          onTaken: () => _onTaken(dose),
          onSkip: () => _onSkip(dose),
          onUndo: () => _onUndo(dose),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Grace-refresh timer
  // ---------------------------------------------------------------------

  /// Cancels any previously scheduled grace-refresh timer and, if [view] has
  /// at least one undoable dose, schedules a single one-shot [Timer] firing
  /// exactly when the soonest undoable dose's grace window elapses. Schedules
  /// no timer when nothing is undoable.
  void _scheduleGraceRefresh(TodayView view, DateTime now) {
    _cancelGraceTimer();

    Duration? minRemaining;
    for (final TodayDose dose in view.doses) {
      final DateTime? confirmedAt = dose.confirmedAt;
      if (!dose.undoable || confirmedAt == null) {
        continue;
      }
      final Duration remaining = confirmedAt
          .toUtc()
          .add(kIntakeUndoGracePeriod)
          .difference(now.toUtc());
      final Duration clamped = remaining.isNegative ? Duration.zero : remaining;
      if (minRemaining == null || clamped < minRemaining) {
        minRemaining = clamped;
      }
    }

    if (minRemaining == null) {
      return;
    }

    _graceTimer = Timer(minRemaining, () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Cancels the pending grace-refresh timer, if any.
  void _cancelGraceTimer() {
    _graceTimer?.cancel();
    _graceTimer = null;
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
        .call(id: intakeId, confirmedAt: confirmedAt, now: clock.now());

    if (!mounted) return;
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.todayActionError)),
      ),
      (_) {},
    );
  }
}
