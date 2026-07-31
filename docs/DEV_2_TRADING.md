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
2. Wire `ExecuteBuyUseCase`, `ExecuteSellUseCase`, `ExecutePortfolioUseCase`, and `ExecuteStopLossUseCase` to concrete infrastructure repositories and authenticated user context.
3. Wire active stop-loss order trigger evaluation to live ticker updates at the application/infrastructure boundary.
4. Add trade history application orchestration around the existing deterministic engine.
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
- `ExecuteStopLossUseCase` is implemented as the application orchestration boundary for active stop-loss evaluation and automatic SELL delegation.
- The use case validates user context, loads the wallet, holdings, active stop-loss orders, and required market tickers, then delegates trigger/quantity/expiry/stale ticker/duplicate/order validity decisions to `StopLossEngine.evaluate`.
- Every generated `SellExecutionRequest` is passed to `ExecuteSellUseCase.execute` through `ExecuteSellRequest.fromStopLoss`; no SELL calculations, wallet updates, holding updates, trade creation, order status writes, database writes, or repository mutations are performed by the stop-loss use case itself.
- Empty stop-loss orders, empty holdings, and no-trigger evaluations succeed gracefully with exact aggregate counts. Engine-rejected orders remain typed `TradingFailure` details inside the evaluation aggregate.
- Application failures cover invalid user context, missing/foreign wallet, wallet/holdings/stop-loss repository failures, holding/order ownership mismatch, malformed active-order repository data, missing/provider-failed market tickers, and delegated `ExecuteSellUseCase` failure.
- Deterministic execution is maintained by copying repository collections, sorting holdings and orders, deriving unique ticker symbols in stable order, and forwarding caller-supplied `evaluatedAt` or a single injected clock value.
- Future `StopLossTriggered` and `AutomaticSellExecuted` event publishing can be inserted after successful orchestration. XP, achievements, badges, missions, and gamification remain outside Laksh's milestone.

## Portfolio Integration Notes
- Divyanshu: provide concrete read-side implementations for `ExecutePortfolioWalletRepository`, `ExecutePortfolioHoldingRepository`, and `ExecutePortfolioTradeRepository`; bind them to the existing `MarketProvider`; keep reads scoped to the authenticated user and do not persist snapshots from this use case.
- Somya: wire portfolio UI/controller/state-management to call `ExecutePortfolioUseCase.execute` with authenticated `userId` and, when needed for deterministic refreshes, a supplied `evaluatedAt`; consume `ExecutePortfolioSuccess.snapshot` and typed failure/domain rejection states.
- Neel: connect future PortfolioViewed gamification through an application event publisher added after successful calculation; do not place XP, badges, achievements, or missions inside the Portfolio Engine.

## Stop-Loss Integration Notes
- Divyanshu: provide concrete implementations for `ExecuteStopLossWalletRepository`, `ExecuteStopLossHoldingRepository`, and `ExecuteStopLossOrderRepository`, bind them to the existing `MarketProvider`, and handle any production stop-loss status persistence/transactions outside this use case.
- Somya: wire dashboard/trading state flows to invoke `ExecuteStopLossUseCase.execute` after authenticated user context and infrastructure bindings exist; render success counts, skipped/rejected details, and delegated sell failures without duplicating trigger logic.
- Neel: consume future `StopLossTriggered` / `AutomaticSellExecuted` application events once an event publisher exists; do not add XP, achievements, badges, or missions to the stop-loss application use case.
