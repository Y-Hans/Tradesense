# Dev Guide — Intelligence & AI Coach (Yajat)

Primary Owner: **Yajat** (Integration Lead)

- Authoritative Ownership Document: [`docs/ownership/Yajat.md`](file:///c:/Users/user/shpathon/docs/ownership/Yajat.md)
- Development Log: [`docs/development-log/Yajat.md`](file:///c:/Users/user/shpathon/docs/development-log/Yajat.md)

## Scope & Owned Directories
- `lib/features/intelligence/`
- `lib/features/coach/`
- `lib/core/utils/risk_calculator.dart`
- `lib/core/utils/discipline_calculator.dart`

## Immediate Tasks
1. Refine the 0-100 Risk Score formula in `RiskCalculator` with exact volatility matrices for BTC, ETH, SOL, XRP, BNB.
2. Refine Discipline Score formula in `DisciplineCalculator` to strictly penalize over-trading and absence of stop-loss protection while remaining 100% independent of P&L profit.
3. Wire the AI Coach client service to call the server-side Supabase Edge Function (`ai-coach`).
4. Ensure structured telemetry logging for future offline AI model fine-tuning datasets.
