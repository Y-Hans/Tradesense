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
