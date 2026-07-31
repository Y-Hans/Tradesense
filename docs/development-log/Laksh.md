# Laksh — Development Log

Role:
Trading Simulator & Portfolio Engine Lead

This file contains meaningful development changes completed by Laksh.

Do not record trivial formatting, variable renames or minor cleanup.

For meaningful completed work, record:

- date
- completed functionality
- important files created
- important files modified
- tests
- integration impact
- known issues

---

## Completed Log Entries

### [2026-07-31] - ExecuteStopLossUseCase Application Orchestration

- **Completed Functionality**: Added `ExecuteStopLossUseCase` as the application-layer orchestration boundary for active stop-loss evaluation and automatic SELL delegation.
- **Important Files Created / Modified**:
  - `lib/features/trading/application/execute_stop_loss_contracts.dart`
  - `lib/features/trading/application/execute_stop_loss_result.dart`
  - `lib/features/trading/application/execute_stop_loss_use_case.dart`
  - `test/unit/trading/fakes/execute_stop_loss_fakes.dart`
  - `test/unit/trading/execute_stop_loss_use_case_test.dart`
  - `docs/ownership/Laksh.md`
  - `docs/DEV_2_TRADING.md`
  - `docs/development-log/Laksh.md`
- **Responsibilities**: The use case trims and validates user context, loads wallet, holdings, active stop-loss orders, and required market tickers, validates ownership/application repository state, delegates stop-loss decisions to `StopLossEngine.evaluate`, and delegates each generated `SellExecutionRequest` to `ExecuteSellUseCase.execute`.
- **StopLossEngine Delegation**: The application layer does not calculate triggers, quantities, expiry, duplicate detection, ticker freshness, validity, or rejected-order `TradingFailure`s.
- **ExecuteSell Delegation**: Triggered orders are converted through `ExecuteSellRequest.fromStopLoss`, preserving `STOP_LOSS` reason, source order id, score snapshots, and deterministic evaluation timestamp while reusing the existing SELL workflow.
- **Typed Results**: `ExecuteStopLossSuccess` exposes exact evaluated, triggered, executed, skipped, pending, expired, and rejected counts plus immutable executed sell summaries. Application failures distinguish invalid user context, missing/foreign wallet, repository/provider failures, malformed active-order repository data, ownership mismatches, and delegated sell failures.
- **Empty Cases**: No active orders, no holdings, and no triggered orders all succeed gracefully. Per-order domain rejections remain in the immutable evaluation aggregate.
- **Determinism**: Repository collections are copied before sorting, ticker symbols are derived from normalized holdings/orders in stable order, caller-supplied `evaluatedAt` is forwarded, and fallback time comes from an injected clock exactly once.
- **Future Event Hook**: A future event publisher can be inserted after successful orchestration for `StopLossTriggered` and `AutomaticSellExecuted`. Gamification remains outside this milestone.
- **Tests**: Added deterministic coverage for success, empty cases, one and multiple triggered sells, one sell call per trigger, delegated sell failure preservation, wallet/repository/market failures, malformed repository data, ownership mismatch, `TradingFailure` preservation, deterministic execution, immutable results, no persistence calls, exact counts, and evaluatedAt forwarding.
- **Integration Impact**: Divyanshu must provide concrete stop-loss read repositories and production order status/transaction integration outside this use case. Somya can consume counts and typed results from UI/controller flows after bindings exist. Neel can later consume application events through a dedicated event publisher.
- **Remaining Work**: Concrete infrastructure bindings, production stop-loss status persistence, authenticated scheduler/live ticker invocation, UI state wiring, event publisher integration, and trade history application orchestration remain outside this milestone.

### [2026-07-30] - ExecutePortfolioUseCase Application Orchestration

- **Completed Functionality**: Added `ExecutePortfolioUseCase` as the application-layer orchestration boundary for read-only portfolio valuation.
- **Important Files Created / Modified**:
  - `lib/features/portfolio/application/execute_portfolio_contracts.dart`
  - `lib/features/portfolio/application/execute_portfolio_result.dart`
  - `lib/features/portfolio/application/execute_portfolio_use_case.dart`
  - `test/unit/portfolio/fakes/execute_portfolio_fakes.dart`
  - `test/unit/portfolio/execute_portfolio_use_case_test.dart`
  - `docs/ownership/Laksh.md`
  - `docs/DEV_2_TRADING.md`
  - `docs/development-log/Laksh.md`
- **Responsibilities**: The use case trims and validates user context, loads wallet, holdings, and trade history through read-side repository contracts, loads current market tickers for unique normalized holding symbols, validates wallet/holding/trade ownership, and delegates all valuation math to `PortfolioEngine.calculate`.
- **Repository / Provider Flow**: The orchestration order is wallet, holdings, trades, then per-symbol market ticker lookups. Empty holdings and empty trades are valid repository responses, and cash-only portfolios skip ticker calls.
- **Portfolio Engine Delegation**: The application layer does not calculate market value, cost basis, allocations, realized P&L, unrealized P&L, returns, totals, or performance highlights. Domain rejections preserve the original `TradingFailure`.
- **Typed Failures**: Application failures cover invalid user context, missing wallet, wallet ownership mismatch, wallet/holdings/trades repository failures, holding/trade ownership mismatch, missing ticker, and market provider failure.
- **Determinism**: The use case copies repository collections before sorting holdings and trades, derives unique ticker symbols deterministically, forwards caller-supplied `evaluatedAt`, and isolates clock usage to the request fallback path.
- **PortfolioViewed Hook**: A future application event publisher can be inserted after successful calculation. XP, achievements, badges, missions, and gamification remain outside this milestone.
- **Tests**: Added deterministic coverage for success, loading and ordering, ticker selection, duplicate symbols, cash-only success, repository/provider failures, missing ticker, ownership mismatches, Portfolio Engine rejection preservation, exact snapshot propagation, no persistence calls, repeated execution determinism, request immutability, collection immutability, and evaluatedAt forwarding.
- **Integration Impact**: Divyanshu must provide concrete read-side repository implementations and wire them with the existing market provider. Somya must call the use case from portfolio UI state/controller flows. Neel can later attach PortfolioViewed handling through a reusable event publisher.
- **Remaining Work**: Concrete infrastructure reads, authenticated user binding, production portfolio UI state wiring, trade history orchestration, stop-loss orchestration, and event publisher integration remain outside this milestone.

### [2026-07-30] - ExecuteSellUseCase Application Orchestration

- **Completed Functionality**: Added `ExecuteSellUseCase` as the application-layer orchestration boundary for manual SELL and stop-loss-generated SELL execution requests.
- **Important Files Created / Modified**:
  - `lib/features/trading/application/execute_sell_contracts.dart`
  - `lib/features/trading/application/execute_sell_result.dart`
  - `lib/features/trading/application/execute_sell_use_case.dart`
  - `lib/features/trading/application/execute_buy_contracts.dart`
  - `test/unit/trading/execute_sell_use_case_test.dart`
  - `test/unit/trading/fakes/execute_buy_fakes.dart`
  - `docs/ownership/Laksh.md`
  - `docs/DEV_2_TRADING.md`
  - `docs/development-log/Laksh.md`
- **Responsibilities**: The use case validates the caller context, loads wallet/holding/ticker state, delegates deterministic SELL calculations to `TradingDomainService.calculateSell`, persists the resulting wallet, holding, and trade through `TradingTransactionRepository.commitSell`, and returns immutable typed success/failure results.
- **Repository Orchestration**: Reuses existing wallet lookup, holding lookup, market ticker provider, and trading transaction repository abstractions. No concrete Supabase, Firebase, SQLite, REST, HTTP, mock storage, provider, or UI production code was added.
- **Manual SELL Flow**: Manual requests pass caller-supplied user id, asset symbol, quantity, trade score snapshots, optional deterministic timestamp, and optional trade id through the same execution path.
- **Stop-Loss SELL Flow**: Stop-loss requests use the existing immutable `SellExecutionRequest` emitted by `StopLossEngine`; the use case preserves the reason and source stop-loss order id while still delegating all financial math to the SELL domain engine.
- **Failure Handling**: Application failures cover invalid user context, invalid request symbol, missing wallet, wallet ownership mismatch, repository load failures, missing/foreign holding, ticker unavailable, market repository failure, id generation failure, transaction persistence failure, and concurrency conflict. Domain rejections preserve the original `TradingFailure`.
- **Transaction Strategy**: SELL persistence is treated as one logical transaction through `TradingTransactionRepository.commitSell`, with expected previous wallet balance, expected previous holding quantity, and optional wallet version supplied for infrastructure-level optimistic concurrency.
- **Tests**: Added deterministic coverage for successful manual SELL, successful stop-loss SELL, missing wallet, missing holding, missing ticker, repository failure, domain rejection, persistence failure, concurrency conflict, update ordering, wallet/holding/trade persistence, input immutability, and determinism.
- **Remaining Work**: Divyanshu must provide concrete transaction-backed repository implementations and stop-loss order status persistence. Somya must wire UI/controller flows after infrastructure bindings exist.

### [2026-07-30] - Deterministic Stop-Loss Engine

- **Completed Functionality**: Added pure `StopLossEngine.evaluate` domain logic that evaluates active stop-loss orders against caller-supplied holdings and market tickers, returning an immutable evaluation aggregate.
- **Important Files Created / Modified**:
  - `lib/features/trading/domain/stop_loss_engine.dart`
  - `lib/features/trading/domain/stop_loss_evaluation_result.dart`
  - `lib/shared/models/stop_loss_order.dart`
  - `test/unit/trading/stop_loss_engine_test.dart`
  - `docs/ownership/Laksh.md`
  - `docs/DEV_2_TRADING.md`
  - `docs/development-log/Laksh.md`
- **Responsibilities**: The engine validates orders, matches holdings, matches tickers, applies expiry rules, evaluates trigger conditions, and separates triggered, pending, expired, rejected, and generated SELL request outputs.
- **Trigger Rule**: Long-only stop-loss orders trigger when current market price is less than or equal to the configured stop price. Prices above the stop remain pending.
- **Generated SELL Requests**: Triggered orders produce immutable `SellExecutionRequest` values containing order id, asset symbol, quantity, market price, trigger price, estimated proceeds, evaluation timestamp, and reason `STOP_LOSS`. No SELL execution is performed.
- **Precision Strategy**: Reuses `FinancialMath.inrToPaise` / `paiseToInr` at INR output boundaries and uses `Decimal` internally for quantity, trigger comparisons, market price comparisons, and estimated proceeds.
- **Failure Handling**: Reuses `TradingFailure` for invalid metadata, invalid symbols, invalid stop prices, invalid quantities, duplicate active order ids, missing tickers, stale tickers, missing holdings, invalid holdings, and oversized stop-loss quantities.
- **Determinism**: Outputs are sorted by normalized asset symbol and order id. The optional evaluation timestamp resolves deterministically from input timestamps when omitted.
- **Future Integration Points**: Divyanshu can provide active order, holding, and ticker retrieval plus status/request persistence at the repository/application boundary. Somya can consume the aggregate through future state management for status displays without owning trigger logic.
- **Remaining Work**: ExecuteSellUseCase, persistence transactions, active ticker evaluation loop, repository implementations, UI wiring, notifications, and production order status updates remain outside this milestone.

### [2026-07-30] - Deterministic Trade History Engine

- **Completed Functionality**: Added a pure `TradeHistoryEngine.calculate` domain operation that accepts immutable `List<Trade>` input plus an optional evaluation timestamp and returns either an immutable trade-history snapshot or typed `TradingFailure` rejection.
- **Important Files Created / Modified**:
  - `lib/features/trading/domain/trade_history_engine.dart`
  - `lib/features/trading/domain/trade_history_result.dart`
  - `test/unit/trading/trade_history_engine_test.dart`
  - `docs/ownership/Laksh.md`
  - `docs/development-log/Laksh.md`
- **Responsibilities**: The engine deterministically sorts by execution timestamp and trade id, builds timeline entries, summarizes BUY/SELL volumes, calculates realized profit/loss statistics, maintains running cumulative cash flow, and exposes per-asset analytics.
- **Statistics**: Snapshot statistics include total trades, BUY/SELL counts, win/loss/break-even rates, largest gain/loss, average gain/loss, profit factor, net realized P&L, trade frequency per day, and trading period.
- **Replay Support**: Replay output exposes ordered trades and per-step reconstruction fields including cash flow, running realized P&L, position quantity, position cost basis, and average entry after each trade. This is intended for future wallet, holdings, portfolio, and analytics reconstruction without adding persistence.
- **Precision Strategy**: Reuses `FinancialMath.inrToPaise` / `paiseToInr` at INR output boundaries and uses `Decimal` internally for quantities, volumes, average cost basis, realized P&L, and rate calculations.
- **Failure Handling**: Reuses `TradingFailure` for invalid trade metadata, duplicate trade ids, non-finite/negative trade financials, future timestamps relative to a supplied evaluation timestamp, and trade-history oversells.
- **Future Integration Points**: Divyanshu can connect persisted trade streams to this pure engine from repositories/application boundaries. Somya can consume the immutable snapshot for future trade history UI, timeline, filters, and statistics panels without owning calculation logic.
- **Remaining Work**: Persistence, repository wiring, provider/controller integration, authenticated user scoping, UI rendering, CSV/PDF export, charts, and production snapshot storage remain outside this milestone.

### [2026-07-29] - Deterministic Portfolio Engine

- **Completed Functionality**: Added a pure `PortfolioEngine.calculate` domain operation that accepts caller-supplied `VirtualWallet`, holdings, market tickers, optional trade history, and an explicit evaluation timestamp. The engine returns an immutable portfolio-domain snapshot or a typed `TradingFailure` rejection.
- **Important Files Created / Modified**:
  - `lib/features/portfolio/domain/portfolio_engine.dart`
  - `lib/features/portfolio/domain/portfolio_engine_result.dart`
  - `test/unit/portfolio/portfolio_engine_test.dart`
  - `docs/ownership/Laksh.md`
  - `docs/development-log/Laksh.md`
- **Inputs**: Domain models only: wallet cash state, `List<Holding>`, `List<MarketTicker>`, optional `List<Trade>`, and evaluation timestamp. No repositories, DTOs, UI, providers, persistence, Supabase, Firebase, HTTP, CoinGecko, or Binance code was added.
- **Outputs**: Immutable aggregate snapshot containing wallet summary, portfolio totals, per-asset summaries, allocation summary, performance highlights, and evaluation timestamp.
- **Calculations**: Per asset, market value is quantity times latest ticker price; cost basis is remaining quantity times average entry; unrealized P&L is market value minus cost basis; return percent is unrealized P&L over cost basis. Portfolio value is cash plus crypto value; total unrealized P&L is the sum of asset unrealized P&L; overall P&L is unrealized plus realized P&L.
- **Realized P&L**: When trades are supplied, realized sell profit/loss is deterministically replayed from trade history using the same proportional average-cost basis rule as the SELL engine. When trades are omitted, realized P&L remains zero.
- **Allocation**: Cash, crypto, and per-asset allocations are calculated against total portfolio value with zero-denominator protection for empty portfolios.
- **Precision Strategy**: Reuses `FinancialMath.inrToPaise` / `paiseToInr` at INR output boundaries and uses `Decimal` for quantity, cost basis, market value, P&L, and percentage calculations before converting to existing double-based model fields.
- **Failure Handling**: Reuses `TradingFailure` and existing codes for invalid wallet state, invalid holdings, invalid or duplicate tickers, stale tickers, invalid trade metadata, and trade-history oversells. No generic exceptions are thrown for expected invalid data.
- **Tests**: Added deterministic portfolio coverage for empty portfolio, wallet-only state, profitable and losing assets, multiple assets, mixed gains/losses, portfolio totals, unrealized P&L, realized P&L, allocation totals, best/worst performers, largest/smallest positions, zero movement, decimal precision, determinism, input immutability, immutable output lists, and invalid data rejection.
- **Future Integration Points**: Divyanshu can connect persisted wallet, holdings, trades, and market ticker providers to the pure engine from repository/application boundaries. Somya can consume the snapshot from a future portfolio controller/provider to render dashboard totals, allocation, and performance highlights.
- **Remaining Before Production Portfolio Is Live**: Concrete persistence reads, authenticated user scoping, live market provider integration, portfolio application boundary, state-management wiring, UI rendering, loading/error states, and production snapshot storage remain outside this milestone.

### [2026-07-29] - Dynamic BUY Application Orchestration Foundation

- **Completed Functionality**: Added `ExecuteBuyUseCase` as the production-facing application boundary around the pure deterministic BUY domain engine. The use case accepts caller-supplied authenticated user id, selected asset, INR buy amount, required trade score snapshots, and optional deterministic timestamps/ids; it dynamically loads persisted wallet state, current holding, and fresh market ticker before invoking `TradingDomainService.calculateBuy`.
- **Contracts Consumed / Added**: Reused the existing `MarketProvider` ticker abstraction and `TradingDomainService`. Added minimal Laksh-owned application contracts for wallet lookup, holding lookup, atomic BUY transaction commit, clock, id generation, persisted wallet ownership/version metadata, and transaction commit results.
- **Atomic Persistence Requirement**: Successful BUY results are persisted only through `TradingTransactionRepository.commitBuy`, which receives the updated wallet, updated holding, created trade, expected previous wallet balance, optional wallet version, and execution timestamp. The use case does not perform independent wallet/holding/trade saves.
- **Concurrency Behavior**: The commit contract exposes optimistic concurrency inputs (`expectedPreviousWalletBalanceInr` and optional `expectedWalletVersion`). A commit conflict maps to a typed application failure and is never reported as success.
- **Typed Results**: `ExecuteBuySuccess` returns updated wallet, updated holding, created trade, execution ticker, deterministic domain BUY details, and commit confirmation. `ExecuteBuyDomainRejected` preserves the original `TradingFailure`. `ExecuteBuyApplicationFailed` distinguishes wallet not found, ownership mismatch, wallet/holding/market repository failures, ticker unavailable, transaction persistence failure, concurrency conflict, invalid user context, and id generation failure.
- **Tests**: Added `test/unit/trading/execute_buy_use_case_test.dart` and `test/unit/trading/fakes/execute_buy_fakes.dart` covering first BUY, repeated BUY, missing wallet, unavailable ticker, stale ticker, insufficient funds, mismatched holding, holding lookup failure, persistence failure, concurrency conflict, determinism, invocation counts, and user isolation for wallet/holding state.
- **Integration Impact**: Divyanshu must provide concrete implementations for the new application contracts, including a Supabase-backed atomic BUY transaction that enforces wallet ownership and optimistic concurrency. Somya can later call the use case from the production trade controller/provider using authenticated user id, selected `CryptoAsset`, INR amount, and current risk/discipline score snapshots; no production screen wiring was added in this task.
- **Known Issues / Remaining Work**: Production BUY still needs concrete persistence, repository wiring, authenticated user source, real market provider behavior, and UI controller integration. SELL, P&L, portfolio valuation, stop-loss execution, Supabase client code, live API code, Firebase, Android, RevenueCat, and production UI remain out of scope.

### [2026-07-28] - Deterministic BUY Trading Domain Engine

- **Completed Functionality**: Added a pure `TradingDomainService.calculateBuy` domain operation for virtual market BUY calculations. The service accepts caller-supplied wallet, asset, ticker, optional existing holding, explicit trade/holding/user identifiers, execution timestamp, and evaluation timestamp; it returns either a typed success result or a machine-readable failure.
- **Important Files Created / Modified**:
  - `lib/features/trading/domain/trading_domain_service.dart`
  - `lib/features/trading/domain/buy_trade_result.dart`
  - `lib/features/trading/domain/trading_failure.dart`
  - `test/unit/trading/trading_domain_service_buy_test.dart`
  - `docs/ownership/Laksh.md`
  - `docs/development-log/Laksh.md`
- **Formulas Used**:
  - Purchased quantity = INR amount spent / execution market price.
  - Updated wallet cash = previous wallet balance - INR amount spent.
  - First holding cost basis = INR amount spent; average entry = execution market price.
  - Repeated holding cost basis = previous cost basis + INR amount spent.
  - Repeated holding weighted average entry = new cost basis / new total quantity.
- **Validation Rules**: Rejects blank/unsupported/invalid assets, invalid trade metadata, zero/negative/non-finite buy amounts, invalid wallet cash state, insufficient funds, zero/negative/non-finite ticker price data, mismatched ticker asset, stale ticker data, mismatched holdings, and invalid existing holding financial state.
- **Precision Strategy**: Reuses `FinancialMath.inrToPaise` / `paiseToInr` at INR boundaries and uses `Decimal` for purchased quantity, cost basis, and weighted average entry calculations. Crypto quantity and average entry are retained to 18 decimal places for model-boundary conversion to existing `double` model fields. No rounding is applied at intermediate calculation steps beyond explicit INR paise normalization.
- **Tests**: Added comprehensive BUY unit coverage for first purchase, repeated purchase weighted average, exact-balance purchase, insufficient funds, invalid amounts, invalid prices, stale ticker, ticker mismatch, invalid holdings, precision-sensitive math, determinism, and no side effects.
- **Integration Impact**: No Supabase, Firebase, HTTP, local storage, UI, navigation, or mock repository integration was added. Future UI/debug harness code can call `TradingDomainService.calculateBuy` and then hand the returned wallet, holding, and trade to persistence/integration layers.
- **Known Issues / Remaining Work**: SELL, realized P&L, unrealized P&L, portfolio valuation, stop-loss execution, persistence transactions, repository implementations, and production UI wiring remain out of scope for later Laksh/integration tasks.

### [2026-07-28] - One Crore Virtual Wallet Initialization Foundation

- **Completed Functionality**: Updated the authoritative `VirtualWallet` initialization semantic from ₹100,000 to ₹1,00,00,000 virtual cash using a single `startingBalanceInr` constant. Added focused portfolio-domain tests proving exact one crore initialization, idempotent factory behavior, preservation of existing financial state, and empty portfolio valuation.
- **Important Files Created / Modified**:
  - `lib/shared/models/virtual_wallet.dart`
  - `test/unit/portfolio/virtual_wallet_initialization_test.dart`
  - `docs/ownership/Laksh.md`
- **Tests**: Added `test/unit/portfolio/virtual_wallet_initialization_test.dart`.
- **Commands Executed**:
  - `dart format .` - completed, but formatter touched many other-owner files; those formatter-only changes were restored.
  - `dart format --output=none --set-exit-if-changed lib\shared\models\virtual_wallet.dart test\unit\portfolio\virtual_wallet_initialization_test.dart` - PASS.
  - `dart format --output=none --set-exit-if-changed .` - failed because 41 pre-existing other-owner files are not formatted according to current Dart formatter output.
  - `flutter pub get` - resolved dependencies but exited with Windows Developer Mode / plugin symlink support warning.
  - `flutter analyze` - PASS.
  - `flutter test` - PASS.
- **Integration Impact**: Other-owner surfaces still reference ₹100,000 and must be updated through the cross-developer process. The shared `VirtualWallet` model is integration-sensitive; consumers should align display text, user profile defaults, mock snapshots, and database defaults before release.
- **Known Issues**: Production wallet persistence and user lifecycle idempotency are not implemented. Existing persisted wallets with explicit `initial_balance_inr` are intentionally preserved and not reset by this change.

### [2026-07-26] — Financial Math Foundation & Mock Trading Engine

- **Completed Functionality**: Created `FinancialMath` utility module with fixed-precision math (paise conversion, weighted average entry price, realised P&L, unrealised P&L, position sizing calculations). Scaffolded mock trading and portfolio repository domain abstractions.
- **Important Files Created / Modified**:
  - `lib/core/utils/financial_math.dart`
- **Tests**: `test/unit/financial_math_test.dart`
- **Integration Impact**: Exposed financial math helper methods consumed by trading engine and portfolio valuation logic.
- **Known Issues**: Real-time ticker stop-loss evaluation loop pending production Supabase trading repository implementation.
