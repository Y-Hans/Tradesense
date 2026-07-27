# Dev Guide — Trading & Portfolio Engine (Laksh)

Primary Owner: **Laksh**

- Authoritative Ownership Document: [`docs/ownership/Laksh.md`](file:///c:/Users/user/shpathon/docs/ownership/Laksh.md)
- Development Log: [`docs/development-log/Laksh.md`](file:///c:/Users/user/shpathon/docs/development-log/Laksh.md)

## Scope & Owned Directories
- `lib/features/trading/domain/` & `data/`
- `lib/features/portfolio/domain/` & `data/`
- `lib/core/utils/financial_math.dart`

## Immediate Tasks
1. Implement production Supabase trading repository (`SupabaseTradingRepository`) executing market orders via RPC / transaction queries.
2. Implement average entry price calculation logic and partial position closing in `FinancialMath`.
3. Support active stop-loss order trigger evaluation loop on live ticker updates.
4. Keep all financial calculations decimal-exact using `FinancialMath.inrToPaise`.
