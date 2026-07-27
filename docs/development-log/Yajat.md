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
