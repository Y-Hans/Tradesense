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

### [2026-07-28] - Debug-Only BUY Engine Real-Device Harness

- **Completed Functionality**: Added an isolated Flutter debug harness for exercising the deterministic BUY domain engine from UI code on a real Android device. The harness is debug-only, in-memory, deterministic, non-production, and does not connect to persistence, live market APIs, repository adapters, Supabase, Firebase, RevenueCat, or external services.
- **Important Files Created / Modified**:
  - `lib/features/trading/presentation/debug/buy_engine_debug_screen.dart`
  - `test/widget/trading/buy_engine_debug_screen_test.dart`
  - `lib/app/routing/app_router.dart`
  - `docs/ownership/Laksh.md`
  - `docs/development-log/Laksh.md`
- **Test Data**: Uses supported BTC test data, a Rs 1,00,00,000 virtual wallet, Rs 1,00,000 first BUY at Rs 50,00,000/BTC, Rs 2,00,000 second BUY at Rs 55,00,000/BTC, explicit UTC timestamps, explicit debug trade/user/holding IDs, discipline score 80, and risk score 25.
- **Integration Impact**: The route `/debug/buy-engine` is registered only when debug routes are enabled. A debug launch can opt into opening the harness first with `--dart-define=BUY_ENGINE_DEBUG_HOME=true`; release behavior remains the normal `/home` route with the debug route omitted.
- **Tests**: Added widget coverage for initial wallet display, first BUY success, repeated BUY weighted-average display, insufficient-funds rejection without state mutation, reset, invalid text input handling, and route omission when debug routes are disabled.
- **Known Issues / Remaining Work**: This harness intentionally does not implement production BUY UI, SELL, analytics, stop-loss, persistence, repository adapters, or live market fetching.

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
