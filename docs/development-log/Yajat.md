# Yajat — Development Log

Role:
Risk, Discipline, AI Coach & Integration Lead

This file contains meaningful development changes completed by Yajat.

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

### [2026-07-26] — Intelligence Engines & AI Coach Domain Foundation

- **Completed Functionality**: Created 0-100 Risk Score calculator (`RiskCalculator`) with asset volatility weightings and concentration penalties. Created 0-100 Discipline Score calculator (`DisciplineCalculator`) strictly penalizing unmanaged risk and over-trading independently of trading P&L profit/loss. Established AI Coach request/response domain models.
- **Important Files Created / Modified**:
  - `lib/core/utils/risk_calculator.dart`
  - `lib/core/utils/discipline_calculator.dart`
  - `lib/shared/models/risk_score.dart`
  - `lib/shared/models/discipline_score.dart`
  - `lib/shared/models/coach_request.dart`
- **Tests**: `test/unit/risk_calculator_test.dart`
- **Integration Impact**: Exposed Risk and Discipline calculators consumed by UI meters and AI Coach explanation context builder.
- **Known Issues**: AI Coach client service currently points to mock provider pending Supabase Edge Function deployment.

### [2026-07-27] — Deterministic Reason-Code System & Risk/Discipline Hardening

- **Completed Functionality**: Formalized typed machine-readable reason code system (`RiskReasonCode`, `DisciplineReasonCode`) in Yajat-owned intelligence domain logic. Integrated deterministic evaluators (`RiskReasonCodeEvaluator`, `DisciplineReasonCodeEvaluator`) mapping calculator inputs and scores to stable string codes without modifying established formulas or shared contracts in `lib/shared/models/`. Substantially strengthened Risk/Discipline unit test suites.
- **Important Files Created / Modified**:
  - `lib/features/intelligence/domain/reason_code.dart`
  - `lib/features/intelligence/domain/risk_reason_code_evaluator.dart`
  - `lib/features/intelligence/domain/discipline_reason_code_evaluator.dart`
  - `test/unit/risk_calculator_test.dart`
  - `test/unit/discipline_calculator_test.dart`
  - `test/unit/intelligence/reason_code_test.dart`
  - `docs/ownership/Yajat.md`
- **Tests**: `test/unit/risk_calculator_test.dart`, `test/unit/discipline_calculator_test.dart`, `test/unit/intelligence/reason_code_test.dart`
- **Integration Impact**: Enables machine-readable deterministic findings for downstream AI Coach context builders without mutating shared contracts.
- **Known Issues**: None.

### [2026-07-27] — Deterministic Reason-Code Threshold Audit & Score Alignment

- **Completed Functionality**: Audited all deterministic Risk and Discipline reason-code thresholds against authoritative scoring formulas. Corrected Discipline position sizing threshold (> 10.0% penalized) and trading frequency threshold (> 5 trades/24h penalized) in `DisciplineReasonCodeEvaluator` to eliminate contradictions between machine-readable reason codes and score component penalties. Preserved all deterministic scoring formulas (`RiskCalculator`, `DisciplineCalculator`) and shared contracts intact. Added boundary and score non-contradiction unit tests.
- **Important Files Modified**:
  - `lib/features/intelligence/domain/reason_code.dart`
  - `lib/features/intelligence/domain/discipline_reason_code_evaluator.dart`
  - `test/unit/intelligence/reason_code_test.dart`
  - `docs/development-log/Yajat.md`
- **Tests**: `test/unit/intelligence/reason_code_test.dart` (5 new boundary & contradiction non-regression tests; 30/30 suite tests passing).
- **Integration Impact**: Guarantees deterministic reason codes strictly align with score component calculations before downstream AI Coach consumption.
- **Known Issues**: None.


