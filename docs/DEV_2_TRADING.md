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
2. Wire `ExecuteBuyUseCase`, `ExecuteSellUseCase`, `ExecutePortfolioUseCase`, `ExecuteStopLossUseCase`, and `ExecuteTradeHistoryUseCase` to concrete infrastructure repositories and authenticated user context.
3. Wire active stop-loss order trigger evaluation to live ticker updates at the application/infrastructure boundary.
4. Keep all financial calculations decimal-exact using `FinancialMath.inrToPaise`.

## Completed Domain Milestones
- `ExecutePortfolioUseCase` is implemented as the application orchestration boundary for read-only portfolio valuation.
- The use case loads the persisted wallet, holdings, trades, and current market tickers for unique held asset symbols before delegating all calculations to `PortfolioEngine.calculate`.
- The use case validates user context plus wallet, holding, and trade ownership, returns typed application failures for repository/provider failures, and preserves `TradingFailure` domain rejections from the Portfolio Engine.
- Empty holdings and empty trades are valid. A user with a valid wallet and no holdings or trades receives the Portfolio Engine's cash-only snapshot without market ticker calls.
- No portfolio persistence, Supabase/Firebase/database code, HTTP, provider/controller code, UI, charts, or navigation was added.
- `ExecutePortfolioUseCase` publishes `PortfolioViewed` through the reusable application-layer `TradingEventPublisher` after successful calculation. Gamification logic remains outside Laksh's domain/application boundary and should be integrated by Neel as an event listener.
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
- `ExecuteStopLossUseCase` publishes `StopLossTriggered` and `AutomaticSellExecuted` through `TradingEventPublisher` after all triggered sell delegations complete successfully. XP, achievements, badges, missions, and gamification remain outside Laksh's milestone.
- `ExecuteTradeHistoryUseCase` is implemented as the application orchestration boundary for read-only trade-history retrieval.
- The use case validates user context, loads the persisted wallet, loads complete trade history, verifies wallet and trade ownership, copies and sorts trades by timestamp and id, then delegates to `TradeHistoryEngine.calculate`.
- The application layer does not calculate running balance, realized P&L, average cost, replay steps, statistics, timeline entries, asset analytics, or cost-basis state. Domain rejections preserve the original `TradingFailure`.
- Empty trade history is valid and returns the successful empty `TradeHistorySnapshot` produced by `TradeHistoryEngine`.
- Typed application failures cover invalid user context, missing/foreign wallet, wallet/trade repository failures, malformed repository ownership data, and trade ownership mismatch.
- Deterministic execution is maintained by copying repository trades before sorting, never relying on repository ordering, forwarding caller-supplied `evaluatedAt`, and using a single injected clock value only as fallback.
- `ExecuteTradeHistoryUseCase` publishes `TradeHistoryViewed` through `TradingEventPublisher` after successful orchestration. XP, achievements, badges, missions, and gamification remain outside Laksh's milestone.
- `ExecuteBuyUseCase` publishes `FirstTradeCompleted` after a successful committed BUY when the completed trade count indicates the user's first committed trade, with a first-holding fallback when no count provider is available.
- `ExecuteSellUseCase` publishes profitable/losing sell outcome events plus `FiveTradesCompleted` and `TenTradesCompleted` when an application-layer completed-trade count provider is available.
- The event system is lightweight and in-memory by default: `TradingEvent`, `TradingEventPublisher`, `TradingEventListener`, `TradingEventSubscription`, `InMemoryTradingEventPublisher`, and `NoOpTradingEventPublisher`.
- Listener lifecycle: consumers subscribe with a callback and unsubscribe either through `TradingEventSubscription.cancel()` or `TradingEventPublisher.unsubscribe(listener)`. Duplicate listener registration is ignored, delivery order is deterministic, and listener exceptions do not break trading execution or other listeners.
- Extension strategy: add a new immutable `TradingEvent` subclass with scalar payload fields, then publish it from the successful application use-case path. Do not add XP, achievements, UI, analytics, notifications, repositories, HTTP, Firebase, or Supabase code to the trading event layer.

## Portfolio Integration Notes
- Divyanshu: provide concrete read-side implementations for `ExecutePortfolioWalletRepository`, `ExecutePortfolioHoldingRepository`, and `ExecutePortfolioTradeRepository`; bind them to the existing `MarketProvider`; keep reads scoped to the authenticated user and do not persist snapshots from this use case.
- Somya: wire portfolio UI/controller/state-management to call `ExecutePortfolioUseCase.execute` with authenticated `userId` and, when needed for deterministic refreshes, a supplied `evaluatedAt`; consume `ExecutePortfolioSuccess.snapshot` and typed failure/domain rejection states.
- Neel: subscribe to `TradingEventPublisher` for `PortfolioViewed` and keep XP, badges, achievements, and missions outside the Portfolio Engine and portfolio use case.

## Stop-Loss Integration Notes
- Divyanshu: provide concrete implementations for `ExecuteStopLossWalletRepository`, `ExecuteStopLossHoldingRepository`, and `ExecuteStopLossOrderRepository`, bind them to the existing `MarketProvider`, and handle any production stop-loss status persistence/transactions outside this use case.
- Somya: wire dashboard/trading state flows to invoke `ExecuteStopLossUseCase.execute` after authenticated user context and infrastructure bindings exist; render success counts, skipped/rejected details, and delegated sell failures without duplicating trigger logic.
- Neel: consume `StopLossTriggered` / `AutomaticSellExecuted` application events through a listener; do not add XP, achievements, badges, or missions to the stop-loss application use case.

## Trade History Integration Notes
- Divyanshu: provide concrete implementations for `ExecuteTradeHistoryWalletRepository` and `ExecuteTradeHistoryTradeRepository`; scope reads to the authenticated user; return complete trade history; do not persist snapshots from this use case.
- Somya: wire the trade history screen/controller/state-management to call `ExecuteTradeHistoryUseCase.execute` with authenticated `userId` and optional deterministic `evaluatedAt`; consume `ExecuteTradeHistorySuccess.snapshot` plus typed failure/domain rejection states without duplicating history calculations.
- Neel: consume `TradeHistoryViewed` events through a listener; do not add XP, achievements, badges, or missions to the trade-history application use case.

## Trading Event System
- Public API: `TradingEventPublisher.subscribe`, `TradingEventPublisher.unsubscribe`, `TradingEventPublisher.publish`, and `TradingEventSubscription.cancel`.
- Supported events: `FirstTradeCompleted`, `FirstProfitableTradeCompleted`, `FirstLosingTradeCompleted`, `PortfolioViewed`, `TradeHistoryViewed`, `FiveTradesCompleted`, `TenTradesCompleted`, `StopLossTriggered`, and `AutomaticSellExecuted`.
- Architecture: application use cases publish immutable `TradingEvent` objects only after successful execution; the publisher owns listener registration and deterministic synchronous fan-out; listeners own all consuming behavior.
- Count milestones: five/ten trade events are emitted when the use case can read a completed count from `TradingCompletedTradeCountProvider`, either injected directly or implemented by the transaction dependency.
