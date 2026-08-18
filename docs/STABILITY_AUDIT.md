# TradeSense Stability Audit

Audit date: 2026-08-14
Scope: current working tree on `app0.9.1`, including uncommitted changes, local Flutter source, tests, generated Dart, Supabase migrations, Edge Functions, configuration, and available Git history.
Audit rule: no application behavior was intentionally changed by this audit; no tests were deleted or restored.

## 1. Executive summary

The repository is not verified production-ready. It is a partially integrated Flutter/Riverpod client with a Supabase backend whose local migration chain, client contracts, and current working-tree changes are inconsistent.

The highest-risk findings are:

1. The working tree contains uncommitted deletions of the OpenRouter client/provider and five related tests, plus `learning_progression_test.dart`. These deletions remove evidence and coverage and must be reviewed before any cleanup.
2. A committed history change deleted `test/widget/network_aware_screens_test.dart`; the deleted file is recoverable from Git and tested offline/stale/error behavior.
3. XP backend migration references `profiles.total_xp`, but the inspected schema does not create that column. The migration chain is therefore not proven applyable.
4. The client has a mock-mode switch that activates whenever Supabase defines are absent. This is useful for UI development but makes a local run materially different from production and can hide missing backend wiring.
5. The current client trading repository invokes `execute_trade`, while the local SQL chain also contains multiple generations of `execute_buy_order`/`execute_sell_order` signatures. The Edge Function uses a service-role client and passes a user ID into a security-definer RPC; caller binding, deployed signatures, and remote migration state are unverified.
6. The UI/domain trading path still receives and calculates with a client market ticker even though the Edge Function obtains the final price. The response is authoritative only if the returned trade is re-read successfully; this split is not covered by integration tests.
7. AI has a real `coach_chat` Edge Function that calls OpenRouter, but the client repository returns a generic fallback on every function failure, swallows history errors, injects a local greeting, and keeps unbounded in-memory history. The deleted direct OpenRouter provider/tests show an architectural migration rather than completed coverage recovery.
8. Home’s Today dashboard is static/mock data (`Future.delayed`, fixed readiness score and fixed coaching copy). Journal now reads trade history, but maps total trade amount into a field named `pnl`, which is semantically incorrect.
9. Authentication has separate verification routes, but the repository exposes a generic `verifyOTP(type)` API, sign-up immediately marks the user authenticated, and password-reset privacy, expiry, resend/cooldown, and recovery-session behavior are not verified end to end.
10. The current automated suite is mostly deterministic unit/widget tests using mocks; it does not prove Supabase session restoration, RLS, migrations, Edge Function auth, real transaction atomicity, OpenRouter authorization, or remote deployment compatibility.

Recommended execution order is P0 database/deployment contract and auth/session foundation, then P1 trading authority and AI authorization, then P2 market/status/UI recovery, followed by coverage hardening and cleanup. No production-readiness claim should be made until the Definition of Done in this document is met.

## 2. Current architecture

### Client

- Flutter app entry point: `lib/main.dart`.
- Riverpod state management: `flutter_riverpod`, generated providers from `riverpod_annotation`.
- Routing: `go_router` with `StatefulShellRoute.indexedStack` in `lib/core/routing/app_router.dart`; generated route/provider output is checked in.
- Authentication: `AuthNotifier` + `AuthRepository`; live implementation is `SupabaseAuthRepository`, development without Supabase defines uses `MockAuthRepository`.
- Persistent local state: `SharedPreferences` via `AppPreferences`; Supabase auth local storage is `SecureLocalStorage`.
- Trading: the main UI uses `TradingRepository`; live implementation is `SupabaseTradingRepository`, which calls `execute_trade` and then reads the inserted trade.
- Market data: Binance REST/WebSocket with CoinGecko fallback, wrapped by cache repositories; mock market mode is selected when Supabase is not configured.
- AI: `CoachRepository` invokes `coach_chat`; `CoachOrchestrator`/`FallbackCoach` remains a deterministic domain fallback path. Deleted OpenRouter client/provider files exist in `HEAD` but not in the current working tree.
- Learning: client-side engines calculate presentation state; current notifier reads `profiles`, `mission_progress`, and `total_xp` directly through Supabase. Backend trade trigger is intended to be authoritative.
- Home features: Today dashboard, market/portfolio summaries, missions, recent activity, and quick actions. Today data is currently static.

### Backend

- Local Supabase migrations: 9 files, timestamps `20260726000000`, `000003`, `000005` through `000010`, and `000012`.
- Local Edge Functions: `ai-coach`, `analyze_trade`, `coach_chat`, `execute_trade`.
- SQL contains initial tables, several replacement RPC generations, RLS changes, idempotency, rate limiting, AI tables, XP tables, and secure RPC replacements.
- No remote Supabase inspection was available in this audit; applied migration state, deployed function versions, secrets, and production RLS are therefore **unknown**, not assumed equal to local files.

### Configuration

- Compile-time values are read from `--dart-define` in `AppConfig`.
- Supabase is initialized only when URL and publishable/anon key are present.
- OpenRouter key is referenced only in the Edge Function in the current tree; it must not be added to Flutter defines.
- `AppConfig.instance` hard-codes development while `AppConfig.resolved()` reads `APP_ENV`; consumers must be checked for using the wrong surface.

## 3. The ten principal problems

### P0-01 — Migration chain is not internally consistent

Evidence: `20260726000010_xp_backend.sql` updates `profiles.total_xp`; the inspected initial schema defines `profiles` without `total_xp`. `20260726000012_secure_rpc.sql` expects `trades.client_order_id`, which is added in `000007`; the initial migration itself also contains older RPC signatures. The chain has destructive `000006_one_time_cleanup.sql` (`DELETE FROM auth.users`) and multiple `CREATE OR REPLACE`/drop/recreate RPC generations.

Root cause: successive AI-assisted backend revisions were added without a single verified schema contract or migration replay test.

Status: blocker; local file inspection proves the inconsistency, but remote applied state is unknown.

### P1-02 — Authentication lifecycle is not proven

Evidence: `AuthNotifier` listens to Supabase events and separately calls `getCurrentUser`; constructor behavior differs between mock/live mode. `signUp` returns a profile and immediately sets `authenticated`, despite the required email-code verification flow. `verifyOTP` accepts a generic string `type`. `resetPasswordForEmail` calls Supabase’s reset API but no client-side account-enumeration-safe result contract is proven. Router reads synchronous onboarding state during asynchronous auth restoration.

Root cause: session restoration, verification, and routing were integrated incrementally without a single explicit state machine and end-to-end tests.

Status: critical; separate screens exist, but required behavior is not verified.

### P1-03 — Trading authority and deployed RPC contract diverge

Evidence: `SupabaseTradingRepository` calls `execute_trade`; SQL defines several RPC generations. `execute_trade` fetches Binance and CoinGecko, then uses service role to call the latest RPC with a caller-supplied `p_user_id`. The final RPC accepts `p_execution_price_inr` and has no visible backend market-price fetch or caller-to-user binding. Client/domain code still uses `executionPriceInr` and local ticker values for calculations.

Root cause: a secure Edge Function path was layered on top of older client/domain contracts rather than replacing the trust boundary end to end.

Status: critical; final execution price is not proven authoritative at the database boundary.

### P1-04 — AI has real and fake paths with swallowed failures

Evidence: `coach_chat` calls OpenRouter server-side, but `CoachRepository.getCoachResponse` catches all errors and returns a generic assistant message. History load errors are swallowed; an in-memory list is authoritative for the current process. `FallbackCoach` and the deleted OpenRouter provider coexist as competing architectures.

Root cause: fallback UX was used as a substitute for observable failure states and provider migration.

Status: critical; real OpenRouter invocation exists, but failure, persistence, ownership, limits, and UI retry are not verified.

### P1-05 — XP/missions backend is incomplete and client/backend models disagree

Evidence: backend trigger creates `verified_events`, first-trade mission progress, and XP ledger, then updates missing `profiles.total_xp`. Client notifier reads this field and derives all mission completion locally. `xp_ledger`, `mission_progress`, and `verified_events` only show SELECT policies in the migration; trigger behavior is not covered by database tests.

Root cause: client progression engine and server authority were integrated without a complete migration and event contract.

Status: critical.

### P2-06 — Market freshness is not represented in the UI contract

Evidence: cache repository supports stale fallback, but `MarketTicker`/screens do not expose a first-class LIVE/STALE/OFFLINE status. Markets screens short-circuit on connectivity and display cached values through generic paths. Trading execution uses a separate Edge Function price source.

Root cause: transport/cache state was implemented without propagating freshness metadata to presentation and execution.

Status: high.

### P2-07 — Home and Journal contain static or semantically fake data

Evidence: `TodayRepository.fetchTodayDashboard` waits 300 ms and returns fixed readiness score and coaching text. `JournalRepository` now reads trades but maps `totalAmountInr` to `JournalState.Trade.pnl`; it returns empty tags and `aiReviewed: false` regardless of backend data.

Root cause: mock screens were connected to live repositories without defining data semantics for dashboard and realized/unrealized P&L.

Status: high.

### P2-08 — Profile and screen error states lose diagnostic information

Evidence: current `ProfileController` catches errors and returns a null profile with no error field. Several home components use `error: (_, __) => SizedBox.shrink()` or fixed fallback content. This creates visually plausible but untrustworthy states and can resemble infinite loading or missing data.

Root cause: UI stabilization changes prioritized rendering over preserving failure state.

Status: high.

### P3-09 — Test suite does not match the architecture

Evidence: 59 test Dart files exist: 49 under `test/unit`, 6 under `test/widget`, 2 feature tests, `test/widget_test.dart`, and one integration test. Auth/onboarding/profile tests mostly use mock repositories. Trading tests target deterministic domain/use-case contracts, not Edge Function/RPC/RLS. No current test covers the required AI, backend XP, migration replay, or real session lifecycle.

Root cause: tests followed old seams and were removed when provider architecture changed.

Status: high coverage-recovery risk.

### P3-10 — Working-tree and generated-code state is not cleanly attributable

Evidence: dozens of modified files and untracked backend/client files are present; checked-in generated files are modified alongside source; OpenRouter provider/tests are deleted. `task.md` does not exist. A clean build/test result could not be established during this audit because `flutter analyze` did not complete within the available command windows.

Root cause: multiple assistant/refactor passes are mixed with current work, with no clean baseline or migration checkpoint.

Status: medium process risk that amplifies every other problem.

## 4. Authentication audit

Required flow versus observed behavior:

| Required state | Current evidence | Assessment |
|---|---|---|
| First install loading | `main()` initializes preferences; router starts `/splash` | Present, not fully verified |
| Get Started/disclaimer | `/welcome`, `/disclaimer` routes exist | Present; persistence/use in router is incomplete |
| Register → email code | register and `/verify-email` screens exist; `signUp` sets authenticated | Broken contract: verification gate is not proven |
| Subsequent launch session restore | Supabase local storage plus `currentSession`/auth events | Race-prone and untested end-to-end |
| Forgot password → recovery code | `/forgot-password`, `/verify-reset-password`, `/set-new-password` exist | Screens exist; provider/API semantics unverified |
| Password update | `updateUser(password)` exists | Requires recovery-session test |
| Logout | repository and notifier exist | Needs event/order/error tests |

Specific gaps: email verification status is not checked before authenticated routing; duplicate registration behavior depends on Supabase response shape and identity list; `OtpType.values.firstWhere` can throw for an unexpected string; resend/cooldown/expiry and password validation need tests; no enumeration-safe user-visible contract is proven. The practical privacy UX should always show the same reset-request success message and navigate to a code screen without confirming whether the address exists; the server should return an indistinguishable response and rate-limit requests.

## 5. Onboarding and startup state machine

Observed startup state:

```text
main initializes SharedPreferences
  -> optional Supabase initialization
  -> ProviderScope/router at /splash
  -> AuthNotifier restoringSession
       -> authenticated(user) or unauthenticated
  -> router checks per-user AppPreferences onboarding flag
       -> /onboarding or /home
```

Risks: router can read `isCompleted` while auth restoration is completing; `RouterListenable` listens to `StateNotifier<void>` and auth but does not await preference initialization itself; the mock user prefix bypasses persistence; the old `OnboardingRepository` still stores completion only in memory and is used by Today/Profile controllers for profile fields; device disclaimer preference is defined but not used by router evidence in this audit. Required first-install versus returning-unauthenticated behavior therefore needs a tested state machine, not inferred route presence.

## 6. Buy/sell audit

Observed live path:

```text
TradeScreen
  -> marketRepository.getTicker (client display/calculation)
  -> SupabaseTradingRepository.executeMarketBuy/Sell
  -> Supabase Edge Function execute_trade
  -> auth.getUser from Authorization header
  -> exchange-discovered native quote + live FX conversion when quote != INR
  -> service-role Supabase RPC
  -> wallet/holding/trade mutation
  -> client selects inserted trade by id
  -> domain/UI event refresh
```

Positive evidence: Edge Function verifies a user, fetches a server price, uses client order IDs, and SQL uses row locks. Risks: fixed FX fallback is hidden inside execution; no timeout/validation is visible around external fetches; current RPC accepts execution price and a user ID from the function without visible binding to the verified JWT; old RPCs and signatures remain in migrations; duplicate client order behavior is not proven because the final SQL must be checked for “existing client_order_id returns existing trade” semantics; response parsing assumes a map and a readable trade row; client error handling can collapse `FunctionException` details.

The client must never be the authority for execution price. The implementation backlog must make the server compute/fetch the price and have the database accept only a server-authorized execution contract, with a test proving a direct client/RPC attempt cannot inject a price.

## 7. Live market data audit

Client path is Binance REST/WebSocket → CoinGecko fallback → cache. Cache policy default is 30 seconds and stale fallback is allowed. Timestamp is created at parse time in several clients, which can make receipt time look like source time. There is no complete UI status model for stale data. Binance and CoinGecko failures, DNS errors, malformed responses, rate limits, and WebSocket reconnect behavior lack end-to-end coverage. Execution intentionally uses a separate server path, but no displayed badge or confirmation explains that distinction.

## 8. Home, Journal, and Profile audit

The four Home feature cards/icons must be mapped from actual `TodayScreen`/shell navigation before implementation. Current routes include Journal, Discipline Meter, Risk Meter, and News Detective; these are distinct from bottom navigation. Journal no longer contains hardcoded fake trade rows in the current diff, which is a positive recovery, but its P&L mapping is wrong and there is no journal-specific repository test. Today still returns mock dashboard content. Profile queries Supabase through `ProfileRepository` in live mode, but controller catch behavior converts failures to an empty profile; `ref.watch` dependencies can recreate/reload the controller and need a lifecycle test against session restoration.

## 9. AI Coach and abuse audit

The current `coach_chat` function authenticates with `getUser`, stores user and assistant messages with a service client, limits daily count to 20, sets a server prompt, and calls OpenRouter with `max_tokens: 500`. It does not atomically increment usage; concurrent requests can race. It trusts client-supplied `history`, does not visibly validate conversation ownership before using a supplied `conversation_id`, does not bound history/message length before constructing the prompt, and returns raw error messages. CORS is `*`. Conversation list/pin/unpin/delete APIs are not present in the current Flutter repository despite schema columns for pinning. The system prompt is a useful starting restriction but needs a balanced policy test matrix: trading education, crypto concepts, risk management, app help should pass; code generation, secret/system-prompt extraction, unrelated expensive work, and role override should refuse.

`ai-coach` is a second Edge Function with overlapping purpose and must be classified as active, dead, or migration-only before implementation. `analyze_trade` is another AI-adjacent function and needs auth/ownership review.

## 10. Database audit

### Actual local tables observed

| Table | Key columns/constraints | RLS/policies observed | Server operation |
|---|---|---|---|
| `profiles` | `id` FK `auth.users`; email, display name, premium, created_at; no `total_xp` in inspected initial schema | `FOR ALL` own-row policy | new-user trigger; XP trigger expects missing column |
| `virtual_wallets` | user_id PK/FK profile; balance, locked, initial, version, updated_at | initial `FOR ALL`, later SELECT-only | buy/sell RPCs |
| `crypto_assets` | symbol PK, name, icon, supported flag | authenticated SELECT | seed/reference data |
| `holdings` | UUID PK; user/profile and asset FKs; unique user/symbol; quantity check; version | initial `FOR ALL`, later SELECT-only | buy/sell RPCs |
| `trades` | UUID PK; user/asset FKs; side/type enums; quantity/score checks; timestamp; client_order_id added later | SELECT own; initial INSERT own then removed | buy/sell RPCs and XP trigger |
| `stop_loss_orders` | UUID PK; trade/user/asset FKs; trigger, quantity, status | `FOR ALL` own-row | buy/sell RPCs |
| `trade_analyses` | trade PK/FK, user FK, JSONB scores/feedback | initial `FOR ALL`, later SELECT-only | `analyze_trade` expected |
| `coach_conversations` | UUID PK; user FK; title, pin, timestamps | `FOR ALL` own-row | coach function/service client |
| `coach_messages` | UUID PK; conversation FK; role check, content, timestamp | `FOR ALL` via conversation ownership | coach function/service client |
| `ai_chat_usage` | user PK/FK; count/reset | own SELECT only | service-role rate limiting |
| `xp_ledger` | UUID PK; user FK; amount/reason/source | own SELECT only | trade trigger |
| `mission_progress` | UUID PK; user FK; unique user/mission | own SELECT only | trade trigger |
| `verified_events` | UUID PK; user FK; event/reference | own SELECT only | trade trigger |

`auth.users` is Supabase-managed and is referenced by profile/auth tables. `delete_user` is called by Flutter but no local function definition was found. Local migration replay and remote history must be tested before any SQL change is selected.

## 11. Previous-agent regression findings

The following changes require explicit review, not automatic restoration:

| Removed/changed | Why it appears removed | Correct next action |
|---|---|---|
| `test/widget/network_aware_screens_test.dart` committed deletion in `e6bc113` | likely UI merge cleanup | recover behavior inventory and replacement coverage for offline/stale/error screens |
| Current deletion of five OpenRouter source/provider tests and five provider/config source files | likely migration from direct Flutter OpenRouter to Edge Function | retain historical tests as evidence; replace with Edge Function contract tests; do not delete until mapped |
| Current deletion of `test/unit/learning_progression_test.dart` | likely compile/architecture mismatch | compare old client engine expectations with backend-authoritative contract and migrate coverage |
| `TodayRepository` fixed dashboard response | previous mock screen retained | replace with explicit data contract or label it demo-only; add success/error/empty tests |
| `CoachRepository` generic fallback on exceptions | user-facing failure smoothing | expose retryable error state and keep fallback only as deliberate offline UX |
| `ProfileController` drops caught error | attempted infinite-loading/compile stabilization | preserve error state and add retry |
| old in-memory onboarding repository still used for fields | partial persistence work | define one source of truth and persist required fields |

## 12. Test & coverage recovery audit

Current count: 59 Dart test files (49 unit, 6 widget, 2 feature, 1 root widget test, 1 integration test). Exact feature matrix is in `docs/TEST_COVERAGE_MATRIX.md`.

Identifiable deleted tests:

- Historical committed deletion: `test/widget/network_aware_screens_test.dart`.
- Current working-tree deletions: `test/unit/coach/coach_cache_providers_test.dart`, `openrouter_ai_provider_test.dart`, `openrouter_dtos_test.dart`, `openrouter_prompt_builder_test.dart`, `openrouter_providers_test.dart`, and `test/unit/learning_progression_test.dart`.

Suspiciously absent coverage: real signup/verification/reset/session restoration; Supabase/RLS/migration replay; Edge Function auth and price authority; duplicate/concurrent trading; market stale/offline semantics; Coach ownership/history/pinning/deletion/rate races/OpenRouter failure; XP trigger/idempotency; profile error/retry; Today data; Journal P&L; generated-code consistency.

Existing tests that are likely seam-level rather than architectural: `auth_repository_test.dart`, `auth_notifier_test.dart`, onboarding/profile widget tests, deterministic trading engines/use cases, and mock repository tests. They remain valuable and must not be deleted; they need contract/integration companions.

## 13. Security audit

- `OPENROUTER_API_KEY`: current hit is server-side in `coach_chat`; no Flutter key exposure found in current search. Verify deployed secret and logs.
- `SUPABASE_SERVICE_ROLE_KEY`: current hit is server-side in `execute_trade`; safe only if function deployment/logging is controlled.
- `password123`: test fixtures only, but should be replaced with clearly synthetic test constants and never reused in deployed data.
- Mock repositories: legitimate dev/test seams, but mock mode is automatic when defines are absent and therefore can conceal missing integration.
- Client-supplied execution price: still present in client contracts/UI/domain and accepted by SQL RPC; high-risk until the final server/database contract removes trust.
- Client XP mutation: no direct mutation method was found in current `LearningProgressionNotifier`; backend trigger is intended authority, but missing schema column and no database tests block confidence.
- CORS `*`, raw Edge Function error messages, unbounded AI input/history, and non-atomic usage upsert are security/abuse risks.

## 14. Error handling, performance, and stability audit

Observed risks: empty catches in auth/profile/coach/learning; fixed mock delays; no visible timeout policy in Edge fetches; possible duplicate provider subscriptions; unbounded `_history`; unbounded coach message query; no pagination; `context.go` and async UI actions need mounted/double-tap review; `TodayScreen` hides errors; stale data status is not preserved. Network-backed screens are inconsistent about Loading/Error/Retry/Empty/Success.

## 15. Stability backlog

### STAB-001 — P0 — Establish a replayable database baseline

Problem/root cause: migration chain has missing `total_xp`, multiple RPC signatures, destructive cleanup, and unknown remote state.

Files: all `supabase/migrations/*.sql`; `docs` deployment notes. Database: all tables/RPCs/triggers.

Dependencies: none. Steps: snapshot local migration hashes; inspect remote migration history; replay from an empty disposable project; add missing/ordered schema contract; classify duplicate migrations; prove rollback/forward strategy; never run cleanup migration against shared data without explicit approval.

Tests/manual: migration replay in disposable Supabase; schema/RLS introspection; `supabase db diff`/equivalent. Done when local chain applies cleanly and remote state is documented.

### STAB-002 — P0 — Define one authoritative auth/startup state machine

Files: `main.dart`, `AuthNotifier`, `SupabaseAuthRepository`, router, onboarding preferences/screens. Database: auth users/profile trigger.

Steps: model restore/unauthenticated/authenticated/unverified/recovery explicitly; separate signup verification and recovery verification APIs; await preference initialization; make router redirect only after restore; define privacy-safe reset response; add resend/cooldown/expiry handling.

Tests: all AUTH and ONBOARDING matrix cases; integration restart/session tests. Done when first install, authenticated restart, and unauthenticated restart follow the required paths without flashes/races.

### STAB-003 — P1 — Make execution price and caller identity backend-authoritative

Files: trading repository/UI/domain contracts, `execute_trade`, final RPC migration. Database: wallet/holdings/trades/RPCs.

Steps: remove client price authority from mutation contract; bind verified JWT user to server operation; use one versioned RPC signature; validate symbol/quantity/side/stop-loss; implement atomic idempotency; define failure mapping; add server timeouts and price-source policy.

Tests/manual: authenticated/unauthenticated, forged price, ownership, insufficient funds/holdings, duplicate/concurrent requests, direct RPC denial, row-lock atomicity. Done when a client cannot choose final price or another user ID.

### STAB-004 — P1 — Recover AI Coach as one bounded server architecture

Files: `CoachRepository`, controller/screens, `coach_chat`, duplicate `ai-coach`/`analyze_trade`, deleted OpenRouter source/tests. Database: coach tables, usage.

Steps: choose one active function; validate conversation ownership; bound message/history/token input; atomic rate-limit reservation; preserve error/retry state; implement history/new/pin/delete contracts; keep key server-side; add balanced role/topic policy.

Tests/manual: AI matrix including injection/refusal/OpenRouter failure/limits/ownership/persistence. Done when real requests reach OpenRouter through the server and failures are observable/retryable.

### STAB-005 — P1 — Repair XP/missions schema and authority

Files: XP notifier/repository/UI; XP migration and trade trigger. Database: `profiles.total_xp`, ledger/events/missions.

Steps: add/verify total XP representation; make verified events unique/idempotent; define all legitimate event types; prevent client mutation; verify trigger behavior and concurrency; make notifier read-only.

Tests/manual: first trade, duplicate trade event, unauthorized mutation, mission completion, ledger/profile consistency. Done when XP can only come from verified backend events.

### STAB-006 — P2 — Propagate market freshness and resilient network state

Files: ticker model/cache/providers/screens/trade display; Edge price utility. Database: none. Steps: add source/fetched-at/freshness status; distinguish live/stale/offline/error; validate malformed responses; add bounded retries/timeouts; document display versus execution source.

Tests/manual: live/cache/stale/offline/retry/malformed/DNS. Done when stale data is never labeled live.

### STAB-007 — P2 — Replace Home mock semantics and repair Journal P&L

Files: Today repository/controller/screen, Journal model/repository/controller/screen, trade/analysis data. Steps: define real dashboard queries; compute P&L from authoritative trades/holdings; remove fixed copy or mark demo; add empty/error/retry states.

Tests/manual: four Home cards, empty journal, real trade history, P&L cases. Done when no fake trades or fake success state appears in production mode.

### STAB-008 — P2 — Preserve Profile and all network-backed error states

Files: profile controller/screen, Home, market, portfolio, missions, coach. Steps: use explicit AsyncValue error state; add retry; guard async navigation/disposal; test auth-restoration dependency.

### STAB-009 — P3 — Reconstruct and migrate deleted coverage

Files: deleted tests listed above plus new integration/database test harness. Steps: archive behavior inventory from Git; do not delete; map each to current architecture; implement equivalent Edge/backend tests; record any genuinely obsolete test with replacement.

### STAB-010 — P3 — Generated code and clean-baseline verification

Files: all `*.g.dart`, `*.freezed.dart`, `pubspec.lock`, package metadata. Steps: obtain clean worktree snapshot; run generator; compare outputs; run analyze/tests with captured logs; separate pre-existing user changes.

### STAB-011 — P3 — Add observability and performance limits

Steps: request IDs, structured safe errors, external-call timeouts, provider disposal, bounded/paginated histories/lists, concurrency guards, cache metrics, rate-limit metrics. Tests/manual load small concurrent scenarios.

## 16. Dependency graph and implementation order

```text
STAB-001 ─┬─> STAB-002 ─> STAB-003 ─> STAB-005
          ├─> STAB-004
          └─> STAB-010
STAB-006 ─> STAB-003 display/execution contract
STAB-007 ─> STAB-008
STAB-009 depends on each finalized contract
STAB-011 follows STAB-002/003/004/006
```

Recommended order: baseline/remote inspection; auth/startup; trading security; AI security; XP authority; market freshness; Home/Journal/Profile; deleted-test migration; generated code and performance. Preserve every failing test while implementing.

## 17. Verification strategy

1. Create a clean branch/worktree or commit a reviewed audit snapshot before implementation.
2. Run Dart format/analyze/generator with exact tool versions and capture output.
3. Run existing tests before modifying them; classify failures without deleting tests.
4. Use repository fakes for deterministic logic, local Supabase for RLS/RPC/trigger integration, and disposable Supabase for migration replay.
5. Deploy Edge Functions to a staging project with test secrets; test JWT, ownership, limits, timeout, and failure paths.
6. Use two authenticated users for cross-account tests.
7. Exercise mobile restart and network transitions manually; verify LIVE/STALE/OFFLINE labels.
8. Review logs for secrets, raw prompts, tokens, and user data before release.

## 18. Definition of done

- Migration chain replays cleanly; remote state and function versions are recorded.
- Auth follows both required launch flows, with separate signup/recovery verification and privacy-safe reset UX.
- Trading is atomic, idempotent, ownership-bound, and server-price-authoritative.
- Market UI labels freshness accurately; execution source is explicitly separate and tested.
- Home features and Journal show real data or a clearly declared empty state; no fake trades.
- Profile and network-backed screens expose loading/error/retry/empty/success states.
- Coach reaches OpenRouter only server-side, persists authorized conversations, enforces bounded usage, and refuses out-of-scope abuse without breaking normal trading education.
- XP/missions are backend-authoritative and replay-safe.
- Deleted tests are either migrated with replacement coverage or documented as genuinely obsolete; no deletion is justified by failure alone.
- Generated code is consistent; analyze, unit/widget/integration/database/Edge tests pass with logs retained.
- No production-readiness claim is made until staging manual verification passes.
