# TradeSense Test Coverage Matrix

Audit date: 2026-08-14. Existing coverage is based on file inspection; a complete green run was not established. `Existing` means a test file appears to cover the seam, not that the production architecture is proven.

Legend: **E** existing seam/unit/widget coverage; **P** partial or mock-only; **M** missing; **R** required recovery test; **I** manual/integration required.

## Current inventory

- 59 Dart test files: 49 unit, 6 widget, 2 feature, 1 root widget, 1 integration.
- Historical committed deletion: `test/widget/network_aware_screens_test.dart`.
- Current working-tree deletions: five OpenRouter tests and `test/unit/learning_progression_test.dart`.
- No database migration/RLS/trigger test suite is present in the repository.

## Matrix

| Area | Behavior | Current coverage | Required recovery/test item |
|---|---|---:|---|
| AUTH | signup | P mock notifier/repository | R real Supabase signup and unverified gate |
| AUTH | duplicate signup | M | R indistinguishable/privacy-safe duplicate behavior |
| AUTH | email OTP verification | M separate screen only | R valid/invalid/expired/resend/cooldown |
| AUTH | login/wrong password | P mock | R live repository error mapping |
| AUTH | logout | P mock | R auth event, router, failed remote logout |
| AUTH | session restore | M | R restart with persisted session and no flash |
| AUTH | forgot password | M | R enumeration-safe request result |
| AUTH | recovery OTP/new password | M | R recovery session, invalid/expired code, update password |
| ONBOARDING | first launch/disclaimer | P mock/in-memory assumptions | R SharedPreferences restart test |
| ONBOARDING | authenticated/unauthenticated restart | M | R state-machine integration tests |
| TRADING | buy/sell | E deterministic use cases; live path M | R Edge/RPC integration |
| TRADING | insufficient funds/holdings | E domain only | R backend constraint and error mapping |
| TRADING | invalid quantity/symbol/stop-loss | P domain | R Edge and RPC validation |
| TRADING | duplicate tap/idempotency | M | R same client order ID and UI guard |
| TRADING | concurrent requests/locks | M | R two concurrent buy/sell integration |
| TRADING | authenticated request | M live | R valid JWT through function |
| TRADING | unauthenticated request | M | R 401 and no mutation |
| TRADING | forged client price/user ID | M | R direct RPC/function attack test |
| MARKET | live Binance price | E serializers/cache only | R network contract/staging smoke |
| MARKET | cache hit | E | add source/freshness assertion |
| MARKET | stale cache | P repository | R UI labels STALE |
| MARKET | offline/error/retry | P historical deleted widget | R recover/migrate deleted test |
| MARKET | malformed/DNS/rate limit | M | R transport parser/retry tests |
| AI | authenticated request | M | R function JWT integration |
| AI | unauthorized/ownership | M | R cross-user conversation test |
| AI | OpenRouter failure | M; client swallows | R visible retry/error contract |
| AI | real OpenRouter server call | deleted direct-provider tests | R Edge contract/staging test without exposing key |
| AI | persistence/history/new chat | P repository path | R multiple conversation integration |
| AI | pin/unpin/delete | M | R API/schema/UI tests |
| AI | rate limit/concurrency | M | R atomic usage reservation and 429 |
| AI | message/history/token limits | M | R oversized input and bounded prompt |
| AI | prompt injection/system prompt | M | R policy matrix |
| AI | unrelated request refusal | M | R code/essay/secret extraction refusal |
| XP | first trade event | M backend | R trigger integration |
| XP | duplicate event/XP | M | R unique event and concurrent replay |
| XP | unauthorized client mutation | M | R RLS negative tests |
| XP | mission completion/profile total | E client engine; backend M | R schema/trigger/profile consistency |
| UI | loading | E selected widgets | add screen-by-screen matrix |
| UI | error/retry | P; some errors hidden | R every network-backed screen |
| UI | empty | E selected | add Journal/portfolio/missions/profile |
| UI | success | E mostly static/mock | R live data smoke |
| HOME | four feature cards | P navigation/widget | R each screen/provider/query/loading/error/empty |
| JOURNAL | no hardcoded trades | current source reads history | R real rows and P&L semantics |
| PROFILE | ownership/session/loading | P mock widget | R auth restore, RLS, error/retry |
| CONFIG | defines/Supabase initialization | M | R configured/unconfigured startup tests |
| DATABASE | migration replay | M | R disposable project replay |
| DATABASE | RLS table policy matrix | M | R two-user SQL integration |
| GENERATED | g.dart/freezed consistency | M | R generator + clean diff |

## Test deletion recovery protocol

Do not delete any listed file because it fails. For each deleted test: recover the test from Git, write down the behavior and fixtures, identify the new production seam, add replacement coverage, then document why the old test is retired. A replacement is not equivalent if it only tests a mock while the old test proved transport, caching, authorization, or persistence behavior.

## Release gates

No release gate is green until existing tests pass, recovered critical tests pass, staging Edge Function/RPC/RLS tests pass, migration replay passes, and manual restart/offline/concurrent-trade/AI-abuse checks are recorded.
