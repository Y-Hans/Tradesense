# Laksh — File Ownership

Role:
Trading Simulator & Portfolio Engine Lead

## Ownership Rules

This developer may modify files explicitly assigned here.

New files created inside clearly owned feature areas should be added to this document.

If a required change belongs to another developer, do not modify that developer's files. Use the cross-developer request process.

## Owned Files

### Core Financial Math & Trading Utilities
- `lib/core/utils/financial_math.dart`

## Owned Areas

- `lib/features/trading/domain/` — Trading domain logic, trade validation, order execution rules, stop-loss trigger logic
- `lib/features/trading/data/` — Trading data sources, local/remote trading repositories, trade history data mapping
- `lib/features/portfolio/domain/` — Portfolio valuation engine, holdings calculation, weighted average entry price, realised P&L, unrealised P&L
- `lib/features/portfolio/data/` — Portfolio data sources and snapshot persistence repositories

## Tests Owned

- `test/unit/financial_math_test.dart`
- `test/unit/portfolio/virtual_wallet_initialization_test.dart`
- `test/unit/trading/*` — Trading engine unit tests
- `test/unit/portfolio/*` — Portfolio and P&L calculation unit tests

## Notes / Boundaries

### Explicit Exclusions (Must NOT Own or Directly Modify):
- Presentation screens and UI widgets (owned by Somya)
- Risk Score formula (0-100) or Discipline Score formula (0-100) (owned by Yajat)
- AI Coach domain logic or OpenRouter integration (owned by Yajat)
- Binance WebSocket stream or CoinGecko network implementation (owned by Divyanshu)
- Supabase auth & account deletion lifecycle (owned by Neel / Divyanshu)
- RevenueCat subscription infrastructure (owned by Divyanshu)
