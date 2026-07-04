# Data Model: Intake-Behavior Settings

## New value objects (settings domain)

### IntakeWindow
Immutable wrapper over a minute count, self-clamping to the valid range.

| Field | Type | Description |
|-------|------|-------------|
| `minutes` | `int` | Actionable window length, **always in [15, 240]** (clamped at construction) |

**Constants**: `minMinutes = 15`, `maxMinutes = 240`, `defaultValue = IntakeWindow._(120)` (const).
**Construction**: public `factory IntakeWindow(int minutes)` → `IntakeWindow._(minutes.clamp(15, 240))`; private `const IntakeWindow._(this.minutes)` for known-valid/const values.
**Equality**: value equality on `minutes` (hand-rolled `==`/`hashCode`).

### GracePeriod
Immutable wrapper over a minute count, self-clamping to the valid range.

| Field | Type | Description |
|-------|------|-------------|
| `minutes` | `int` | Undo grace length, **always in [0, 30]** (clamped at construction) |

**Constants**: `minMinutes = 0`, `maxMinutes = 30`, `defaultValue = GracePeriod._(5)` (const).
**Construction / Equality**: same shape as `IntakeWindow`.

## Changed entity

### AppSettings (`lib/features/settings/domain/entities/app_settings.dart`)
Adds three fields to the existing `@freezed` entity (existing four unchanged).

| Field | Type | Default | Meaning |
|-------|------|---------|---------|
| `intakeWindow` | `IntakeWindow` | `IntakeWindow.defaultValue` (120) | How long after `scheduledAt` a dose stays actionable |
| `gracePeriod` | `GracePeriod` | `GracePeriod.defaultValue` (5) | How long a confirmed dose can be undone |
| `allowMarkAhead` | `bool` | `false` | Whether a dose may be marked before its window opens |

`@Default(...)` requires a compile-time constant → the const `static defaultValue` on each VO is what makes the VO-typed defaults legal.

## Validation Rules

| Rule | Where enforced |
|------|----------------|
| `intakeWindow.minutes ∈ [15, 240]` | `IntakeWindow` factory (single clamp implementation) |
| `gracePeriod.minutes ∈ [0, 30]` | `GracePeriod` factory |
| Out-of-range persisted value normalized on read | Data-source getters pass the raw stored int through the VO factory → clamped |
| Missing persisted value | Data-source getter falls back to `VO.defaultValue.minutes` / `false` |

## Persistence mapping (SharedPreferences)

| Key (new) | Stored type | Read → domain | Write |
|-----------|-------------|---------------|-------|
| `intakeWindowMinutes` | `int` | `IntakeWindow(getInt(key) ?? 120)` | `setInt(key, value.minutes)` |
| `gracePeriodMinutes` | `int` | `GracePeriod(getInt(key) ?? 5)` | `setInt(key, value.minutes)` |
| `allowMarkAhead` | `bool` | `getBool(key) ?? false` | `setBool(key, value)` |

All three keys are added to `settingsPrefsKeys` (`lib/core/providers/settings_prefs_keys.dart`), which is the `SharedPreferencesWithCache` `allowList` — so the cache admits them automatically.
