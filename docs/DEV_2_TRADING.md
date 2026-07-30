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
2. Wire `ExecuteBuyUseCase`, `ExecuteSellUseCase`, and `ExecutePortfolioUseCase` to concrete infrastructure repositories and authenticated user context.
3. Wire active stop-loss order trigger evaluation to live ticker updates at the application/infrastructure boundary.
4. Add trade history and stop-loss application orchestration around the existing deterministic engines.
5. Keep all financial calculations decimal-exact using `FinancialMath.inrToPaise`.

## Completed Domain Milestones
- `ExecutePortfolioUseCase` is implemented as the application orchestration boundary for read-only portfolio valuation.
- The use case loads the persisted wallet, holdings, trades, and current market tickers for unique held asset symbols before delegating all calculations to `PortfolioEngine.calculate`.
- The use case validates user context plus wallet, holding, and trade ownership, returns typed application failures for repository/provider failures, and preserves `TradingFailure` domain rejections from the Portfolio Engine.
- Empty holdings and empty trades are valid. A user with a valid wallet and no holdings or trades receives the Portfolio Engine's cash-only snapshot without market ticker calls.
- No portfolio persistence, Supabase/Firebase/database code, HTTP, provider/controller code, UI, charts, or navigation was added.
- A future `PortfolioViewed` event publisher can be inserted after a successful calculation. Gamification logic remains outside Laksh's domain/application boundary and should be integrated by Neel through a future event system.
- Deterministic stop-loss evaluation is implemented in `StopLossEngine.evaluate`.
- The engine validates active stop-loss orders, matches holdings and tickers, evaluates `current market price <= stop price`, and emits immutable SELL execution requests with reason `STOP_LOSS`.
- The engine does not execute trades, mutate wallets, mutate holdings, write history, persist orders, fetch market data, or notify users.
- `ExecuteSellUseCase` is implemented as the application orchestration boundary for manual SELL and stop-loss SELL requests.
- The use case loads wallet, holding, and ticker state, delegates all financial calculations to `TradingDomainService.calculateSell`, commits updated wallet, updated holding, and generated trade through `TradingTransactionRepository.commitSell`, and returns typed success/failure results.
- Future integration must load active orders, holdings, and market tickers, call the pure engine, persist status transitions, and pass generated requests to `ExecuteSellUseCase`.

## Portfolio Integration Notes
- Divyanshu: provide concrete read-side implementations for `ExecutePortfolioWalletRepository`, `ExecutePortfolioHoldingRepository`, and `ExecutePortfolioTradeRepository`; bind them to the existing `MarketProvider`; keep reads scoped to the authenticated user and do not persist snapshots from this use case.
- Somya: wire portfolio UI/controller/state-management to call `ExecutePortfolioUseCase.execute` with authenticated `userId` and, when needed for deterministic refreshes, a supplied `evaluatedAt`; consume `ExecutePortfolioSuccess.snapshot` and typed failure/domain rejection states.
- Neel: connect future PortfolioViewed gamification through an application event publisher added after successful calculation; do not place XP, badges, achievements, or missions inside the Portfolio Engine.
