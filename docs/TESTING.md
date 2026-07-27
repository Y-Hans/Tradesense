# Testing Infrastructure Guide

## 1. Unit Testing Strategy (`test/unit/`)
Unit tests verify deterministic business logic without UI or backend network calls:
- `financial_math_test.dart`: Precision INR paise conversions & percentage math.
- `risk_calculator_test.dart`: 0-100 Risk score weighted matrix verification.
- `discipline_calculator_test.dart`: 0-100 Discipline score process adherence verification.

## 2. Widget Testing Strategy (`test/widget/`)
Widget tests verify presentation screens rendering with Riverpod mocks:
- `home_screen_test.dart`: Dashboard wallet balance and asset list render verification.

## 3. Integration Testing Strategy (`integration_test/`)
Integration tests run full end-to-end user flows in Flutter engine:
- `app_test.dart`: Launch app -> view ₹100,000 balance -> select BTC -> place market BUY -> verify P&L & AI Coach explanation screen.
