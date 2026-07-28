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
