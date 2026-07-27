# Module Integration Map & Architectural Flow

Managed by: `Yajat` (Integration Lead)

This document visualizes high-level module dependencies, data pipelines, and vendor abstractions across the Crypto Trading Simulator architecture.

---

## 1. Core Data & Application Flow

```text
+------------------------------------+
|  Authentication / User Lifecycle   | (Neel — AuthRepository / Supabase Auth)
+------------------------------------+
                  |
                  v
+------------------------------------+
|   Virtual Account Initialization   | (Neel / Laksh — ₹100,000 Virtual Wallet)
+------------------------------------+
                  |
                  v
+------------------------------------+
|     Market Data Ticker Stream      | (Divyanshu — Binance WS / CoinGecko Fallback)
+------------------------------------+
                  |
                  v
+------------------------------------+
|    Trading Engine & Stop-Loss      | (Laksh — Virtual BUY/SELL, StopLossOrder)
+------------------------------------+
                  |
                  v
+------------------------------------+
|   Portfolio & P&L Valuation        | (Laksh — Holdings, Average Entry, Realised/Unrealised P&L)
+------------------------------------+
                  |
                  v
+------------------------------------+
|      Risk & Discipline Engine      | (Yajat — 0-100 Risk Score, 0-100 Discipline Score)
+------------------------------------+
                  |
                  v
+------------------------------------+
|           AI Trade Coach           | (Yajat — AIProvider / Edge Function Context)
+------------------------------------+
                  |
                  v
+------------------------------------+
|      Flutter Presentation UI       | (Somya — Screens, Gauges, Riverpod UI State)
+------------------------------------+
```

---

## 2. Subscription & Feature Flag Pipeline

```text
+------------------------------------+
|       RevenueCat / Google Play     | (Divyanshu — purchases_flutter SDK)
+------------------------------------+
                  |
                  v
+------------------------------------+
|      SubscriptionProvider          | (Divyanshu — Abstract Subscription Status)
+------------------------------------+
                  |
                  v
+------------------------------------+
|       Premium Feature Access       | (Somya / Yajat — Paywall Gating & AI Coach Access)
+------------------------------------+
```

---

## 3. AI Coach Abstraction & Future Model Transition

```text
+------------------------------------+
|         AI Coach Domain            | (Yajat — Prompt Builder & Telemetry Logger)
+------------------------------------+
                  |
                  v
+------------------------------------+
|            AIProvider              | (Abstract Provider Interface)
+------------------------------------+
           /            \
          /              \
         v                v
+------------------+    +--------------------------+
| OpenRouterProvider|    | CustomModelProvider      |
| (V1 — OpenRouter |    | (Future — Internal       |
|   Edge Function) |    |   Trained AI Model)      |
+------------------+    +--------------------------+
```

---

## 4. Integration Tagging Convention

To synchronize parallel developer progress, the Integration Lead uses release/integration tags:

- `integration-v1-001` — Initial Architecture & Model Baseline
- `integration-v1-002` — Core Backend Services Integration
- `integration-v1-003` — Production Feature Complete
- `integration-v1-rc1` — Release Candidate Verification
