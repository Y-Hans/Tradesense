# Dev Guide — UI / UX / Presentation (Somya)

Primary Owner: **Somya**

- Authoritative Ownership Document: [`docs/ownership/Somya.md`](file:///c:/Users/user/shpathon/docs/ownership/Somya.md)
- Development Log: [`docs/development-log/Somya.md`](file:///c:/Users/user/shpathon/docs/development-log/Somya.md)

## Scope & Owned Directories
- `lib/app/theme/`
- `lib/shared/widgets/`
- `lib/features/**/presentation/`

## Immediate & Current Tasks
1. Refine the glassmorphic card design and animations in `TodayScreen`, `HomeScreen`, `MarketsScreen`, and `TradeScreen`.
2. Ensure high contrast readability for financial charts, risk meters, discipline meters, and P&L cards.
3. Align presentation UI with canonical backend modules (`neel/auth-session-lifecycle`, `laksh-trading-complete`, `yajat/risk-discipline-ai`).
4. Resolve all verified UI issues: terms disclosure modal, reactive profile setup validation, removal of redundant import trade CTA, dynamic user greeting, functional Today action plans, dynamic AI coach provider abstraction, light theme default with working theme toggle, privacy policy and help/support screens, push notification permission flow, functional app bar action icons, dynamic simulator portfolio valuation, and zero dead UI elements.
5. Do NOT write domain business logic or financial calculations. Consume state strictly from Riverpod providers (`portfolioProvider`, `userLifecycleNotifierProvider`, `coachOrchestratorProvider`, `supportedAssetsProvider`).
