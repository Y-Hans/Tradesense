-- 20260726000016_trades_realized_pnl.sql
-- Adds realized_pnl column to public.trades table.

ALTER TABLE public.trades
  ADD COLUMN IF NOT EXISTS realized_pnl NUMERIC;
