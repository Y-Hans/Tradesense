# Integration Request: CoachResultScreen Trade Lookup

**From**: Yajat
**To**: Somya
**Status**: Implemented

## Request
- **Context**: The `CoachResultScreen` was previously using a hardcoded fallback BTC trade instead of resolving the actual trade being evaluated.
- **Goal**: Dynamically look up the trade by its ID when rendering the Coach Result Screen.
- **Constraints**:
  - Do NOT modify `TradingRepository` or add new contract methods like `getTradeById()`.
  - Use `FutureProvider.family` to watch `tradingRepositoryProvider`, call `getTradeHistory()`, and filter for the correct trade locally.
  - Show proper AsyncLoading, AsyncError, and a clear "Trade Not Found" state if the ID is missing.
  - Add widget tests for both successful render and the "Trade Not Found" state by mocking `getTradeHistory()`.

## Implementation Notes
- Created `tradeByIdProvider` (a `FutureProvider.family<Trade?, String>`) in `lib/features/coach/presentation/coach_result_screen.dart`.
- Replaced the hardcoded `Trade` instantiation with `tradeAsync.when`.
- Display a fallback `Center(child: Text('Trade Not Found'))` when the trade doesn't exist in history.
- Added `test/features/coach/presentation/coach_result_screen_test.dart` injecting a `FakeTradingRepository` to mock history and validated the UI updates properly.
