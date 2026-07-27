# Architecture Blueprint — Feature-First Clean Architecture

Managed by: `Yajat` (Integration Lead)

## Directory Layout
```
lib/
├── app/
│   ├── app.dart
│   ├── routing/
│   └── theme/
├── core/
│   ├── config/
│   ├── constants/
│   ├── contracts/
│   ├── errors/
│   ├── networking/
│   ├── providers/
│   └── utils/
├── shared/
│   ├── models/
│   └── widgets/
└── features/
    ├── auth/
    ├── onboarding/
    ├── market/
    ├── trading/
    ├── portfolio/
    ├── intelligence/
    ├── coach/
    ├── subscription/
    ├── learning/
    └── profile/
```

## Vendor Decoupling Rules
1. UI components depend ONLY on Riverpod providers exposing abstract domain contracts.
2. Concrete vendor implementations (Binance, Supabase, OpenRouter, RevenueCat, Firebase) exist in `lib/core/providers/` and feature `data/` layers.
3. Feature code MUST NEVER directly import vendor SDKs (`supabase_flutter`, `purchases_flutter`, `firebase_analytics`).

---

## Multi-Developer Governance & Documentation Rules

### Individual Developer Ownership Documents
Each developer normally modifies ONLY:
`docs/ownership/<their-name>.md`
when they create, delete, move, or rename an owned file. Developers must **NOT** modify another developer's ownership document.

### Individual Development Logs
Each developer normally modifies ONLY:
`docs/development-log/<their-name>.md`
after meaningful completed work.

### Central Documentation Management
`Yajat` (Integration Lead) manages and reconciles central project documentation:
- `docs/CURRENT_STATE.md`
- `docs/ARCHITECTURE.md`
- `docs/DECISIONS.md`
- `docs/INTEGRATION_MAP.md`
- `docs/SHARED_CONTRACTS.md`
- `docs/ownership/shared.md`

### Integration Requests
Cross-developer requests are managed via:
- `docs/integration-requests/open/`
- `docs/integration-requests/resolved/`
- `docs/INTEGRATION_REQUESTS.md`

---

## Post-Merge Workflow

After a significant integration merge:
1. Integration Lead uses a pre-merge context/readiness check when appropriate.
2. Human Integration Lead performs the Git merge.
3. Integration Lead runs post-merge reconciliation against the **ACTUAL** merged repository.
4. Build, analyze, and test validations are performed.
5. Central documentation, especially `docs/CURRENT_STATE.md`, is updated and reconciled.
6. Integration tag/commit (e.g. `integration-v1-002`) is recorded.
7. Feature developers pull/sync from the updated integrated baseline branch.
8. AI planning agents consume the updated documentation baseline before generating new task plans.
