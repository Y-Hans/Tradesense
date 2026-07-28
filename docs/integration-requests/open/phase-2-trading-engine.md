# Phase 2 Trading Engine Integration Request

**Requested from:** Laksh (Trading Simulator & Portfolio Engine), Divyanshu (Market Data)

## Context

Phase 2 presentation now consumes the existing mock repository contracts for virtual order execution, portfolio display, close-position actions, and simulated ticker streams.

## Required domain follow-up

1. Revalue open holdings from the current market ticker so portfolio unrealised P&L changes with simulated ticks.
2. Persist and expose realised P&L when a holding is partially or fully sold.
3. Provide a portfolio-state notifier or stream through the existing contract so UI refreshes do not rely on manual invalidation.
4. Keep the frozen V1 scope: BTC, ETH, SOL, XRP, BNB and a ₹100,000 virtual INR starting balance.

## UI impact

The presentation layer already displays portfolio, market movement, and close-position states. It can consume the above contract additions without modifying financial formulas or shared models.
