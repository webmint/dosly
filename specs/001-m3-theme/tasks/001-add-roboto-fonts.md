# Task 001: Add Roboto fonts and declare in pubspec

**Agent**: mobile-engineer
**Files**:
- `assets/fonts/Roboto-Light.ttf` *(create)*
- `assets/fonts/Roboto-Regular.ttf` *(create)*
- `assets/fonts/Roboto-Medium.ttf` *(create)*
- `assets/fonts/Roboto-Bold.ttf` *(create)*
- `assets/fonts/LICENSE.txt` *(create)*
- `assets/fonts/SOURCE.md` *(create)*
- `pubspec.yaml` *(modify)*

**Depends on**: None
**Blocks**: 003 (text theme references the family name), 008 (DoslyApp won't render correctly without the font available)
**Review checkpoint**: No
**Context docs**: None

## Description

Bundle the four Roboto TTF weights as static assets and declare them in `pubspec.yaml` so Flutter resolves `fontFamily: 'Roboto'` to the correct file at every weight. This is the foundation for the M3 type scale (which uses weights 400/500 mostly) and lets the app render identical typography on iOS and Android. Also update the `pubspec.yaml` description from the `flutter create` placeholder to a real one.

This task is **bulk asset addition** — it touches 7 files but is a single logical change (a font family is inseparable from its declaration). This is the documented exception to the 1-3-files-per-task rule.

**Manual download required**: the four TTF files come from the official Google Fonts release. Download from `https://fonts.google.com/specimen/Roboto`. If the implementer can't reach the internet, they MUST stop and prompt the user to drop the four files into `assets/fonts/` manually.

## Change details

- Create `assets/fonts/` directory.
- Download from `https://fonts.google.com/specimen/Roboto`:
  - `Roboto-Light.ttf` (weight 300)
  - `Roboto-Regular.ttf` (weight 400)
  - `Roboto-Medium.ttf` (weight 500)
  - `Roboto-Bold.ttf` (weight 700)
  - Skip weight 600 — not in the Material 3 type scale.
- Create `assets/fonts/LICENSE.txt` containing the Apache 2.0 license text from the Google Fonts download bundle.
- Create `assets/fonts/SOURCE.md` recording:
  - Source URL: `https://fonts.google.com/specimen/Roboto`
  - Download date: 2026-04-11
  - SHA-256 hashes of the four `.ttf` files (compute with `shasum -a 256 assets/fonts/Roboto-*.ttf`)
- In `pubspec.yaml`:
  - Replace `description: "A new Flutter project."` with `description: "Personal medication tracking app."`
  - Under the `flutter:` block (after `uses-material-design: true`), add:
    ```yaml
      fonts:
        - family: Roboto
          fonts:
            - asset: assets/fonts/Roboto-Light.ttf
              weight: 300
            - asset: assets/fonts/Roboto-Regular.ttf
              weight: 400
            - asset: assets/fonts/Roboto-Medium.ttf
              weight: 500
            - asset: assets/fonts/Roboto-Bold.ttf
              weight: 700
    ```
- After editing pubspec.yaml, run `flutter pub get` to refresh the asset manifest.

## Done when

- [x] All four `Roboto-*.ttf` files exist under `assets/fonts/` and are non-zero in size
- [x] `assets/fonts/LICENSE.txt` exists and contains the **OFL 1.1** license text *(deviation from spec — see Completion Notes)*
- [x] `assets/fonts/SOURCE.md` exists with source URL, date, and SHA-256 hashes
- [x] `pubspec.yaml` declares all four Roboto weights under `flutter.fonts` with the correct `weight:` for each
- [x] `pubspec.yaml` `description` field reads `Personal medication tracking app.`
- [x] `flutter pub get` completes without errors
- [x] `dart analyze` is clean (this task changes no Dart code, but a successful pub-get is verified)

## Spec criteria addressed

AC-5

## Completion Notes

**Status**: Complete
**Completed**: 2026-04-11
**Files changed**:
- `pubspec.yaml` (modified — description + fonts block)
- `assets/fonts/Roboto-Light.ttf` (353 636 bytes, weight 300)
- `assets/fonts/Roboto-Regular.ttf` (353 292 bytes, weight 400)
- `assets/fonts/Roboto-Medium.ttf` (353 688 bytes, weight 500)
- `assets/fonts/Roboto-Bold.ttf` (355 504 bytes, weight 700)
- `assets/fonts/LICENSE.txt` (4394 bytes — SIL OFL 1.1)
- `assets/fonts/SOURCE.md` (1709 bytes)

**Contract**: Expects 2/2 verified | Produces 5/5 verified

**Notes**:
- **License deviation**: task spec assumed Roboto is Apache 2.0, but Roboto v3 (the version actually distributed by Google Fonts) is **SIL Open Font License 1.1**. The original 2011 Roboto was Apache 2.0; the v3 family was re-licensed. Shipping OFL.txt is the legally correct call. Documented in `SOURCE.md`.
- **Source**: downloaded `Roboto_v3.015.zip` from `googlefonts/roboto-3-classic` GitHub release (the canonical source for compiled static weights; `google/fonts` only ships the variable font now).
- **SHA-256 hashes**:
  - Light: `704c7d1d6b851ed08dba35551fff5bb93ca88a09eb352920839c830708f8a950`
  - Regular: `bc98207f422864e757a2b97884b2d592aecd94e4494d93938c99679680e9a7a8`
  - Medium: `d733f4e7f9507e519792f836f32d5350358a3800f9689b0bedce4cbfb51225c4`
  - Bold: `d3ffd8647f664dd11fb13b40753d850f4bebf100fcd2bf1b26c314c6a2d63e85`
- **Code review verdict**: APPROVE (re-verified file integrity, magic bytes, SHA-256 hashes match SOURCE.md).

## Contracts

### Expects
- `pubspec.yaml` exists with the standard `flutter create` boilerplate (verified — created by `flutter create .`)
- `flutter` is on PATH (verified — used for `pub get`)

### Produces
- Files `assets/fonts/Roboto-Light.ttf`, `Roboto-Regular.ttf`, `Roboto-Medium.ttf`, `Roboto-Bold.ttf` exist on disk
- `pubspec.yaml` contains the literal string `family: Roboto` under a `flutter.fonts` list entry
- `pubspec.yaml` contains `weight: 300`, `weight: 400`, `weight: 500`, `weight: 700` (one per declared TTF asset entry)
- `pubspec.yaml`'s top-level `description:` field contains the string `Personal medication tracking app.`
