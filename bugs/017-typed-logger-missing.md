# Bug 017: Typed logger from `core/logging/` does not exist

**Status**: Open
**Severity**: Medium
**Source**: spec 013 spin-off (originally flagged inside bug 002 description)
**Reported**: 2026-05-01
**Fixed**:

## Description

Constitution §7.1 step #3 prescribes the creation of a typed logger at
`lib/core/logging/logger.dart` (consider `package:logging` + a sanitize
layer). The file does not yet exist.

Constitution §4.2.1 [enforced]: "Never use `print()` or `debugPrint()` in
committed code. Use the typed logger from `core/logging/`. The `avoid_print`
lint must remain enabled."

Constitution §4.2.1 [enforced]: "Never log medication names, dosages, or
intake history. These are sensitive PHI even for personal use. The logger
must have a sanitize layer."

The combination is load-bearing: §4.2.1 forbids `debugPrint` and requires
the logger to exist as the compliant alternative, but the logger itself
hasn't been built. Until it lands, every code path that "wants to log
something" is forced to either (a) propagate the failure to the UI, or
(b) silently drop the diagnostic — neither of which is a true logging
posture.

This was originally noted inside bug 002's description as "a separate gap"
and is being formally tracked here so spec 013 (the bug 002 fix) can
explicitly cite it as out-of-scope rather than allowing it to drop off the
radar.

## File(s)

| File | Detail |
|------|--------|
| lib/core/logging/logger.dart | Does not exist. Should be created per constitution §7.1 step #3. |

## Evidence

`constitution.md:88` (file inventory in §2.2):
```
│   ├── logging/logger.dart                  # typed logger (no print/debugPrint anywhere else)
```

`constitution.md:560–562` (§7.1 first-files-to-create order):
```
3. `lib/core/logging/logger.dart` — typed logger (consider `package:logging` + a sanitize layer)
```

`constitution.md:359` (§4.2.1):
```
- [enforced] **Never log medication names, dosages, or intake history.**
  These are sensitive PHI even for personal use. The logger must have a
  sanitize layer.
```

`bugs/002-debugprint-in-settings-provider.md:21–23`:
> The typed logger (`lib/core/logging/logger.dart`, prescribed by constitution
> §7.1 step #3) does not exist yet, which is itself a separate gap. Once it
> lands, all four sites should route through it (with a sanitize layer per §4.2.1
> PHI rule).

`ls lib/core/` returns: `error/`, `providers/`, `routing/`, `theme/`, `widgets/`
— no `logging/` directory.

## Fix Notes

Suggested approach (to be confirmed in `/specify`):

1. Add `package:logging` (or pick an alternative — `logger`, `talker`) as a
   runtime dependency.
2. Create `lib/core/logging/logger.dart` exposing a single typed logger
   instance plus level helpers (`info`, `warning`, `severe`).
3. Implement a **sanitize layer** that strips PHI tokens before any
   message is emitted. At minimum: medication names, dosages, intake
   timestamps, schedule strings. The sanitizer is the most important
   piece — without it, the typed logger is no better than `debugPrint`
   for §4.2.1 compliance.
4. Wire a single `loggerProvider` (Riverpod) so call sites can consume it
   via `ref.read(loggerProvider).warning(...)` instead of importing a
   bare top-level instance (testability + override-in-tests).
5. Land separately from spec 013 so the logger arrives with proper test
   coverage of the sanitize layer (the sanitize layer is the security
   surface — it must have its own tests).

This bug is a prerequisite for any future code path that needs to record
a non-fatal diagnostic without surfacing it to the UI. Spec 013 deliberately
defers any logging at the four `debugPrint` sites until this lands.
