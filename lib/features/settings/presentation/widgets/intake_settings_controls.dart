/// Settings feature — intake behaviour controls widget.
///
/// Exports [IntakeSettingsControls], a [ConsumerWidget] that renders two
/// −/+ stepper rows (intake window, grace period) and a [SwitchListTile]
/// (allow mark-ahead). State is read from and written to
/// [settingsNotifierProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/value_objects/grace_period.dart';
import '../../domain/value_objects/intake_window.dart';
import '../providers/settings_provider.dart';

/// A compound widget that lets the user control intake behaviour.
///
/// Contains:
/// - A stepper row for the intake window (how long after the scheduled time
///   a dose can still be marked), stepping by 15 minutes within
///   [IntakeWindow.minMinutes]..[IntakeWindow.maxMinutes].
/// - A stepper row for the grace period (how long an intake can be undone
///   after being marked), stepping by 5 minutes within
///   [GracePeriod.minMinutes]..[GracePeriod.maxMinutes].
/// - A [SwitchListTile] for whether doses may be marked before their window
///   opens.
///
/// Persistence failures are surfaced by the parent [SettingsScreen]'s
/// listener on `settingsErrorsProvider`; this widget does not show its own
/// error UI — on failure the notifier simply leaves `state` unchanged, so the
/// displayed values stay in sync with what is actually persisted.
class IntakeSettingsControls extends ConsumerWidget {
  /// Creates the intake settings controls widget.
  const IntakeSettingsControls({super.key});

  static const int _intakeWindowStepMinutes = 15;
  static const int _gracePeriodStepMinutes = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow watches: only rebuild when these fields change, not on any
    // unrelated AppSettings field (e.g. theme or language toggles).
    final intakeWindow = ref.watch(
      settingsNotifierProvider.select((s) => s.intakeWindow),
    );
    final gracePeriod = ref.watch(
      settingsNotifierProvider.select((s) => s.gracePeriod),
    );
    final allowMarkAhead = ref.watch(
      settingsNotifierProvider.select((s) => s.allowMarkAhead),
    );
    final l10n = context.l10n;
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntakeStepperTile(
          label: l10n.settingsIntakeWindowLabel,
          description: l10n.settingsIntakeWindowDescription,
          valueLabel: l10n.settingsMinutesValue(intakeWindow.minutes),
          decrementEnabled: intakeWindow.minutes > IntakeWindow.minMinutes,
          incrementEnabled: intakeWindow.minutes < IntakeWindow.maxMinutes,
          onDecrement: () => notifier.setIntakeWindow(
            IntakeWindow(intakeWindow.minutes - _intakeWindowStepMinutes),
          ),
          onIncrement: () => notifier.setIntakeWindow(
            IntakeWindow(intakeWindow.minutes + _intakeWindowStepMinutes),
          ),
        ),
        _IntakeStepperTile(
          label: l10n.settingsGracePeriodLabel,
          description: l10n.settingsGracePeriodDescription,
          valueLabel: l10n.settingsMinutesValue(gracePeriod.minutes),
          decrementEnabled: gracePeriod.minutes > GracePeriod.minMinutes,
          incrementEnabled: gracePeriod.minutes < GracePeriod.maxMinutes,
          onDecrement: () => notifier.setGracePeriod(
            GracePeriod(gracePeriod.minutes - _gracePeriodStepMinutes),
          ),
          onIncrement: () => notifier.setGracePeriod(
            GracePeriod(gracePeriod.minutes + _gracePeriodStepMinutes),
          ),
        ),
        SwitchListTile(
          title: Text(l10n.settingsAllowMarkAheadLabel),
          subtitle: Text(l10n.settingsAllowMarkAheadDescription),
          value: allowMarkAhead,
          // Zero horizontal padding — the parent Padding widget already
          // provides the 16 px horizontal inset.
          contentPadding: EdgeInsets.zero,
          onChanged: notifier.setAllowMarkAhead,
        ),
      ],
    );
  }
}

/// A single −/+ stepper row used by [IntakeSettingsControls].
///
/// Renders a [ListTile]-like row with [label] as the title and [description]
/// as the subtitle, and a trailing decrement/increment control pair around
/// [valueLabel]. [onDecrement]/[onIncrement] are `null` (disabling the
/// respective button) when [decrementEnabled]/[incrementEnabled] is `false`.
class _IntakeStepperTile extends StatelessWidget {
  /// Creates a stepper row.
  const _IntakeStepperTile({
    required this.label,
    required this.description,
    required this.valueLabel,
    required this.decrementEnabled,
    required this.incrementEnabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  /// The row's title text.
  final String label;

  /// The row's subtitle text, explaining what the value controls.
  final String description;

  /// The current value, already formatted for display (e.g. "120 min").
  final String valueLabel;

  /// Whether the decrement button is enabled.
  final bool decrementEnabled;

  /// Whether the increment button is enabled.
  final bool incrementEnabled;

  /// Called when the decrement button is pressed. Ignored (button disabled)
  /// when [decrementEnabled] is `false`.
  final VoidCallback? onDecrement;

  /// Called when the increment button is pressed. Ignored (button disabled)
  /// when [incrementEnabled] is `false`.
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      // Zero horizontal padding — the parent Padding widget already provides
      // the 16 px horizontal inset.
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.minus),
            tooltip: l10n.settingsStepperDecreaseTooltip,
            onPressed: decrementEnabled ? onDecrement : null,
          ),
          Text(valueLabel),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: l10n.settingsStepperIncreaseTooltip,
            onPressed: incrementEnabled ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}
