# TradeSense Logo

Place your application logo here as `logo.png`.

## Requirements

- File name: `logo.png` (exact)
- Recommended size: **1024×1024 px** (square, will be scaled)
- Format: PNG with transparency supported
- Location: `assets/images/logo.png`

## Where it appears automatically

Once you add `logo.png` and run `flutter pub get`, the logo will automatically
appear in:

| Location | Widget | Size |
|---|---|---|
| Login screen | `AppLogo(size: 64)` | 64×64 |
| App bar (horizontal layout) | `AppLogo.horizontal(size: 32)` | 32×32 + wordmark |
| Splash screen (if wired) | `AppLogo(size: 120)` | 120×120 |

## Fallback behaviour

If `logo.png` is absent, the UI automatically falls back to the branded gradient
`AIAvatar` icon — so the app never shows a broken image placeholder.

## No further code changes required

The `AppLogo` widget in `lib/shared/widgets/app_logo.dart` handles everything.
