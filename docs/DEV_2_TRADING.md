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
2. Wire `ExecuteBuyUseCase` and `ExecuteSellUseCase` to concrete infrastructure repositories and authenticated user context.
3. Wire active stop-loss order trigger evaluation to live ticker updates at the application/infrastructure boundary.
4. Keep all financial calculations decimal-exact using `FinancialMath.inrToPaise`.

## Completed Domain Milestones
- Deterministic stop-loss evaluation is implemented in `StopLossEngine.evaluate`.
- The engine validates active stop-loss orders, matches holdings and tickers, evaluates `current market price <= stop price`, and emits immutable SELL execution requests with reason `STOP_LOSS`.
- The engine does not execute trades, mutate wallets, mutate holdings, write history, persist orders, fetch market data, or notify users.
- `ExecuteSellUseCase` is implemented as the application orchestration boundary for manual SELL and stop-loss SELL requests.
- The use case loads wallet, holding, and ticker state, delegates all financial calculations to `TradingDomainService.calculateSell`, commits updated wallet, updated holding, and generated trade through `TradingTransactionRepository.commitSell`, and returns typed success/failure results.
- Future integration must load active orders, holdings, and market tickers, call the pure engine, persist status transitions, and pass generated requests to `ExecuteSellUseCase`.
