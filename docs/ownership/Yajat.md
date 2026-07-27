# Yajat — File Ownership

Role:
Risk, Discipline, AI Coach & Integration Lead

## Ownership Rules

This developer may modify files explicitly assigned here.

New files created inside clearly owned feature areas should be added to this document.

If a required change belongs to another developer, do not modify that developer's files. Use the cross-developer request process.

## Owned Files

### Core Intelligence Utilities & Calculators
- `lib/core/utils/risk_calculator.dart`
- `lib/core/utils/discipline_calculator.dart`

### Intelligence Domain Reason Codes & Evaluators
- `lib/features/intelligence/domain/reason_code.dart`
- `lib/features/intelligence/domain/risk_reason_code_evaluator.dart`
- `lib/features/intelligence/domain/discipline_reason_code_evaluator.dart`

### Provider-Independent AI Coach Domain Foundation
- `lib/features/coach/domain/coach_context.dart`
- `lib/features/coach/domain/coach_context_builder.dart`
- `lib/features/coach/domain/coach_orchestrator.dart`
- `lib/features/coach/domain/fallback_coach.dart`


### Central Integration & Coordination Documentation (Lead Responsibility)
- `docs/ARCHITECTURE.md`
- `docs/CURRENT_STATE.md`
- `docs/DECISIONS.md`
- `docs/INTEGRATION_MAP.md`
- `docs/SHARED_CONTRACTS.md`
- `docs/ownership/shared.md`

## Owned Areas

- `lib/features/intelligence/domain/` — 0-100 Risk Score formula, 0-100 Discipline Score formula, volatility matrices, trade penalization logic
- `lib/features/intelligence/data/` — Intelligence score data providers and history tracking
- `lib/features/coach/domain/` — AI Coach domain models, prompt framing, deterministic trade analysis, telemetry schemas
- `lib/features/coach/data/` — Client-side AI coach service abstractions (AIProvider calling Supabase Edge Function)

## Tests Owned

- `test/unit/risk_calculator_test.dart`
- `test/unit/discipline_calculator_test.dart`
- `test/unit/intelligence/*` — Risk and discipline engine unit tests
- `test/unit/coach/*` — AI Coach domain and request/response unit tests

## Notes / Boundaries

### Integration Lead Authority & Boundaries:
- As **Integration Lead**, Yajat manages central project state (`CURRENT_STATE.md`), shared contracts (`SHARED_CONTRACTS.md`), architectural decisions (`DECISIONS.md`), and shared contract coordination.
- **CRITICAL**: Integration Lead status does **NOT** grant permission to casually modify other developers' feature code or files without using the cross-developer integration request process.
- Must preserve vendor-decoupled `AIProvider` architecture: V1 uses OpenRouter via Supabase Edge Function; future architecture targets transition to custom trained model.

### Explicit Exclusions (Must NOT Own or Directly Modify):
- Presentation UI screens and layout widgets (owned by Somya)
- Authoritative trading engine, position valuation, and P&L math (owned by Laksh)
- Supabase auth, user lifecycle, and learning progression (owned by Neel)
- Binance WebSocket market client, Supabase DB migrations, RevenueCat SDK, Android Gradle build files (owned by Divyanshu)
