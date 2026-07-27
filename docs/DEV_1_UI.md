# Dev Guide — UI / UX / Presentation (Somya)

Primary Owner: **Somya**

- Authoritative Ownership Document: [`docs/ownership/Somya.md`](file:///c:/Users/user/shpathon/docs/ownership/Somya.md)
- Development Log: [`docs/development-log/Somya.md`](file:///c:/Users/user/shpathon/docs/development-log/Somya.md)

## Scope & Owned Directories
- `lib/app/theme/`
- `lib/shared/widgets/`
- `lib/features/**/presentation/`

## Immediate Tasks
1. Refine the glassmorphic card design and animations in `HomeScreen` and `TradeScreen`.
2. Ensure high contrast readability for financial charts and P&L cards.
3. Build custom widgets for Risk Meter and Discipline Meter visual gauges in `lib/shared/widgets/`.
4. Do NOT write domain business logic or financial calculations. Consume state from Riverpod providers (`portfolioProvider`, `supportedAssetsProvider`, `subscriptionStatusProvider`).
