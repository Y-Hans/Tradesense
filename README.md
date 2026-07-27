# Gamified Crypto Trading Education Simulator ("CryptoEdu")

[![CI](https://github.com/shipathon/cryptoedu/actions/workflows/ci.yml/badge.svg)](https://github.com/shipathon/cryptoedu/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.8-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-grade, pragmatic Clean Architecture Flutter application designed for a **Shipathon/Hackathon** and publication on Google Play.

## 🎯 Product Vision & Core Philosophy

**"Profit does not necessarily mean you made a good decision."**

Users practice crypto trading with **₹100,000 VIRTUAL CASH** using real live prices without real-money transactions, deposits, or wallet connections.

The app evaluates trading behavior through two core metrics before invoking the server-side AI Coach:
1. **Trading Discipline Score (0-100)**: Process adherence independent of profit.
2. **Portfolio Risk Score (0-100)**: Explainable risk metric (concentration, position sizing, volatility, stop-loss presence).

---

## 👥 5-Developer Ownership Matrix

To enable 5 developer agents to branch concurrently from the exact same commit without merge conflicts:

| Developer Role | Area Owned | Directory Boundaries |
| :--- | :--- | :--- |
| **DEV 1 — UI/UX** | Design system, screens, theme | `lib/shared/widgets/`, `lib/app/theme/`, `lib/features/**/presentation/` |
| **DEV 2 — Trading & Engine** | Virtual wallet, BUY/SELL, P&L, holdings | `lib/features/trading/domain/`, `lib/features/portfolio/domain/` |
| **DEV 3 — Intelligence & AI** | Risk meter, Discipline meter, AI Coach | `lib/features/intelligence/`, `lib/features/coach/` |
| **DEV 4 — Lifecycle & Learning** | Auth, onboarding, profile, missions | `lib/features/auth/`, `lib/features/onboarding/`, `lib/features/profile/`, `lib/features/learning/` |
| **DEV 5 — Platform & Backend** | Market APIs, Supabase, RevenueCat, Android, CI | `lib/core/networking/`, `supabase/`, `android/`, `.github/` |

> See [FILE_OWNERSHIP.md](docs/FILE_OWNERSHIP.md) for strict rules and [INTEGRATION_REQUESTS.md](docs/INTEGRATION_REQUESTS.md) for contract modification logs.

---

## ⚡ Quick Start

### 1. Run Offline in Mock Mode (No credentials required!)
```bash
flutter pub get
flutter run
```
The app defaults to `mockModeProvider = true` allowing complete testing of the entire user journey with zero backend API dependencies.

### 2. Verify Code Quality & Test Suite
```bash
flutter format --set-exit-if-changed .
flutter analyze
flutter test
```

---

## 📚 Documentation Sitemap

- [PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md)
- [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [V1_SCOPE.md](docs/V1_SCOPE.md)
- [FILE_OWNERSHIP.md](docs/FILE_OWNERSHIP.md)
- [DEV_1_UI.md](docs/DEV_1_UI.md)
- [DEV_2_TRADING.md](docs/DEV_2_TRADING.md)
- [DEV_3_INTELLIGENCE.md](docs/DEV_3_INTELLIGENCE.md)
- [DEV_4_ACCOUNT_LEARNING.md](docs/DEV_4_ACCOUNT_LEARNING.md)
- [DEV_5_PLATFORM.md](docs/DEV_5_PLATFORM.md)
- [SHARED_CONTRACTS.md](docs/SHARED_CONTRACTS.md)
- [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md)
- [AI_ARCHITECTURE.md](docs/AI_ARCHITECTURE.md)
- [SUBSCRIPTIONS.md](docs/SUBSCRIPTIONS.md)
- [INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md)
- [INTEGRATION_REQUESTS.md](docs/INTEGRATION_REQUESTS.md)
- [ENVIRONMENT_SETUP_WINDOWS.md](docs/ENVIRONMENT_SETUP_WINDOWS.md)
- [ANDROID_DEVELOPMENT.md](docs/ANDROID_DEVELOPMENT.md)
- [GOOGLE_PLAY_RELEASE.md](docs/GOOGLE_PLAY_RELEASE.md)
- [SECURITY.md](docs/SECURITY.md)
- [PRIVACY.md](docs/PRIVACY.md)
- [TESTING.md](docs/TESTING.md)
