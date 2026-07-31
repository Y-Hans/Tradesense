# Gamified Crypto Trading Education Simulator ("CryptoEdu")

[![CI](https://github.com/shipathon/cryptoedu/actions/workflows/ci.yml/badge.svg)](https://github.com/shipathon/cryptoedu/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.8-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-grade, pragmatic Clean Architecture Flutter application designed for a **Shipathon/Hackathon** and publication on Google Play.

---

## 🎯 Product Vision & Core Philosophy

**"Profit does not necessarily mean you made a good decision."**

Users practice crypto trading with **₹100,000 VIRTUAL CASH** using real live prices without real-money transactions, deposits, or wallet connections.

The app evaluates trading behavior through two core metrics before invoking the server-side AI Coach:
1. **Trading Discipline Score (0-100)**: Process adherence independent of profit.
2. **Portfolio Risk Score (0-100)**: Explainable risk metric (concentration, position sizing, volatility, stop-loss presence).

---

## 🚀 Current Status: Prototype Merged & Verified

Neel's prototype features have been integrated and verified in this local repository:
- **Authentication & User Lifecycle**: Login, Register, Session restoration.
- **Idempotent Wallet Initialization**: ₹100,000 VIRTUAL starting balance.
- **Educational Onboarding**: 3-step slide walkthrough with completion state persistence.
- **Missions & Rewards**: 5 educational missions (+50 to +150 XP) with duplicate reward prevention.
- **Deterministic Level Progression**: Rookie ➔ Explorer ➔ Risk-Aware Trader ➔ Disciplined Trader.
- **News Detective Quiz**: 15 curated questions teaching source verification and clickbait detection.
- **Educational Disclaimers**: Non-real trading disclaimers integrated across UI screens.
- **Code Quality**: Passes `flutter analyze` with 0 issues.

---

## 👥 5-Developer Ownership Matrix

| Developer Role | Area Owned | Directory Boundaries |
| :--- | :--- | :--- |
| **DEV 1 — UI/UX** | Design system, screens, theme | `lib/shared/widgets/`, `lib/app/theme/`, `lib/features/**/presentation/` |
| **DEV 2 — Trading & Engine** | Virtual wallet, BUY/SELL, P&L, holdings | `lib/features/trading/domain/`, `lib/features/portfolio/domain/` |
| **DEV 3 — Intelligence & AI** | Risk meter, Discipline meter, AI Coach | `lib/features/intelligence/`, `lib/features/coach/` |
| **DEV 4 — Lifecycle & Learning** | Auth, onboarding, profile, missions | `lib/features/auth/`, `lib/features/onboarding/`, `lib/features/profile/`, `lib/features/learning/` |
| **DEV 5 — Platform & Backend** | Market APIs, Supabase, RevenueCat, Android, CI | `lib/core/networking/`, `supabase/`, `android/`, `.github/` |

---

## ⚡ Quick Start

### 1. Run Offline in Mock Mode (No credentials required!)
```bash
flutter pub get
flutter run
```

### 2. Verify Code Quality & Test Suite
```bash
flutter analyze
flutter test
```

---

## 📚 Documentation Sitemap

- [CURRENT_STATE.md](docs/CURRENT_STATE.md)
- [DECISIONS.md](docs/DECISIONS.md)
- [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [SHARED_CONTRACTS.md](docs/SHARED_CONTRACTS.md)
- [OWNERSHIP.md](docs/ownership/OWNERSHIP.md)
- [LOG.md](docs/development-log/LOG.md)
- [INTEGRATION.md](docs/integration-requests/INTEGRATION.md)
