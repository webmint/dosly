/// Meds feature — shared icon resolver for [MedicationForm] values.
///
/// This library exposes a single public function, [medicationFormIcon],
/// which maps every [MedicationForm] enum value to its Lucide icon.
/// It is the single source of truth for form icons shared by the
/// add-medication form picker and the medications-list tile.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/medication_form.dart';

/// Returns the Lucide icon representing a medication [form], shared by the
/// add-medication form picker and the medications-list tile.
///
/// Uses an exhaustive [switch] (no `default:`) over all 8 [MedicationForm]
/// values so the compiler enforces completeness when new values are added.
IconData medicationFormIcon(MedicationForm form) {
  switch (form) {
    case MedicationForm.tablet:
      return LucideIcons.tablets;
    case MedicationForm.capsule:
      return LucideIcons.pill;
    case MedicationForm.syrup:
      return LucideIcons.milk;
    case MedicationForm.drops:
      return LucideIcons.droplets;
    case MedicationForm.injection:
      return LucideIcons.syringe;
    case MedicationForm.inhaler:
      return LucideIcons.wind;
    case MedicationForm.cream:
      return LucideIcons.bandage;
    case MedicationForm.sachet:
      return LucideIcons.package;
  }
}
