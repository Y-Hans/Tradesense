# Somya — File Ownership

Role:
UI/UX, Visual Design & Flutter Presentation Lead

## Ownership Rules

This developer may modify files explicitly assigned here.

New files created inside clearly owned feature areas should be added to this document.

If a required change belongs to another developer, do not modify that developer's files. Use the cross-developer request process.

## Owned Files

### Presentation Screens & Views
- `lib/app/theme/app_theme.dart`
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/market/presentation/markets_screen.dart`
- `lib/features/market/presentation/asset_detail_screen.dart`
- `lib/features/trading/presentation/trade_screen.dart`
- `lib/features/portfolio/presentation/portfolio_screen.dart`
- `lib/features/portfolio/presentation/trade_history_screen.dart`
- `lib/features/intelligence/presentation/discipline_meter_screen.dart`
- `lib/features/intelligence/presentation/risk_meter_screen.dart`
- `lib/features/coach/presentation/coach_result_screen.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/register_screen.dart`
- `lib/features/onboarding/presentation/onboarding_screen.dart`
- `lib/features/profile/presentation/profile_screen.dart`
- `lib/features/learning/presentation/missions_screen.dart`
- `lib/features/subscription/presentation/paywall_screen.dart`

## Owned Areas

- `lib/app/theme/` — Visual design tokens, color palette, dark mode styles, typography
- `lib/shared/widgets/` — Shared reusable UI widgets, gauge meters, cards, buttons
- `lib/features/*/presentation/` — All screen layouts, dialogs, widgets, animations, UI accessibility, and presentation-level Riverpod state UI hooks

## Tests Owned

- `test/widget/home_screen_test.dart`
- `test/widget/*` — All presentation and UI widget tests

## Notes / Boundaries

### Explicit Exclusions (Must NOT Own or Directly Modify):
- Authoritative trading engine calculations or position sizing math (owned by Laksh)
- Realised/unrealised P&L formulas (owned by Laksh)
- Risk Score formula or Discipline Score formula logic (owned by Yajat)
- AI Coach prompt engineering or backend integration (owned by Yajat)
- Supabase authentication/database persistence implementations (owned by Neel / Divyanshu)
- Market data REST/WebSocket client network implementations (owned by Divyanshu)
- RevenueCat or Google Play Billing SDK logic (owned by Divyanshu)
