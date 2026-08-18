-- 20260726000013_idempotent_rpc.sql
-- Drops ALL prior execute_buy_order / execute_sell_order overloads.
-- Creates single canonical service-role-only versions with idempotent early-exit pattern.

-- Drop ALL known overloads
DROP FUNCTION IF EXISTS public.execute_buy_order(TEXT, NUMERIC, NUMERIC, INTEGER, NUMERIC, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.execute_buy_order(TEXT, NUMERIC, NUMERIC, NUMERIC, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.execute_buy_order(TEXT, NUMERIC, NUMERIC, NUMERIC, UUID);
DROP FUNCTION IF EXISTS public.execute_buy_order(UUID, TEXT, NUMERIC, NUMERIC, NUMERIC, UUID);
DROP FUNCTION IF EXISTS public.execute_sell_order(TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.execute_sell_order(TEXT, NUMERIC, NUMERIC, UUID);
DROP FUNCTION IF EXISTS public.execute_sell_order(UUID, TEXT, NUMERIC, NUMERIC, UUID);

CREATE OR REPLACE FUNCTION public.execute_buy_order(
  p_user_id             UUID,
  p_symbol              TEXT,
  p_quantity            NUMERIC,
  p_execution_price_inr NUMERIC,
  p_stop_loss_price_inr NUMERIC DEFAULT NULL,
  p_client_order_id     UUID    DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_total_cost     NUMERIC;
  v_wallet_balance NUMERIC;
  v_trade_id       UUID;
  v_discipline_score INTEGER;
  v_risk_score       INTEGER;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID is required';
  END IF;

  -- IDEMPOTENCY GUARD: return existing trade if same client_order_id before any mutation
  IF p_client_order_id IS NOT NULL THEN
    SELECT id INTO v_trade_id
    FROM public.trades
    WHERE client_order_id = p_client_order_id AND user_id = p_user_id;
    IF FOUND THEN
      RETURN v_trade_id; -- no-op, idempotent
    END IF;
  END IF;

  v_total_cost := p_quantity * p_execution_price_inr;

  v_risk_score := 50;
  v_discipline_score := CASE WHEN p_stop_loss_price_inr IS NOT NULL THEN 85 ELSE 45 END;

  -- Lock wallet to prevent concurrent balance mutation
  SELECT balance_inr INTO v_wallet_balance
  FROM public.virtual_wallets
  WHERE user_id = p_user_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  IF v_wallet_balance < v_total_cost THEN
    RAISE EXCEPTION 'Insufficient funds: required %, available %', v_total_cost, v_wallet_balance;
  END IF;

  UPDATE public.virtual_wallets
  SET balance_inr = balance_inr - v_total_cost,
      version     = version + 1,
      updated_at  = NOW()
  WHERE user_id = p_user_id;

  INSERT INTO public.holdings (user_id, symbol, quantity, average_entry_price_inr)
  VALUES (p_user_id, p_symbol, p_quantity, p_execution_price_inr)
  ON CONFLICT (user_id, symbol) DO UPDATE SET
    average_entry_price_inr =
      ((public.holdings.quantity * public.holdings.average_entry_price_inr) + v_total_cost)
      / (public.holdings.quantity + EXCLUDED.quantity),
    quantity   = public.holdings.quantity + EXCLUDED.quantity,
    version    = public.holdings.version + 1,
    updated_at = NOW();

  -- UNIQUE constraint on client_order_id provides atomic second-layer safety against concurrent races
  INSERT INTO public.trades (
    user_id, symbol, side, type, quantity,
    execution_price_inr, total_amount_inr,
    stop_loss_price_inr, discipline_score_at_trade,
    risk_score_at_trade, client_order_id
  )
  VALUES (
    p_user_id, p_symbol, 'buy'::trade_side, 'market'::order_type, p_quantity,
    p_execution_price_inr, v_total_cost,
    p_stop_loss_price_inr, v_discipline_score,
    v_risk_score, p_client_order_id
  )
  RETURNING id INTO v_trade_id;

  IF p_stop_loss_price_inr IS NOT NULL THEN
    INSERT INTO public.stop_loss_orders (trade_id, user_id, symbol, trigger_price_inr, quantity)
    VALUES (v_trade_id, p_user_id, p_symbol, p_stop_loss_price_inr, p_quantity);
  END IF;

  RETURN v_trade_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.execute_sell_order(
  p_user_id             UUID,
  p_symbol              TEXT,
  p_quantity            NUMERIC,
  p_execution_price_inr NUMERIC,
  p_client_order_id     UUID DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_total_proceeds   NUMERIC;
  v_trade_id         UUID;
  v_holding_id       UUID;
  v_existing_qty     NUMERIC;
  v_discipline_score INTEGER := 45;
  v_risk_score       INTEGER := 50;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID is required';
  END IF;

  -- IDEMPOTENCY GUARD
  IF p_client_order_id IS NOT NULL THEN
    SELECT id INTO v_trade_id
    FROM public.trades
    WHERE client_order_id = p_client_order_id AND user_id = p_user_id;
    IF FOUND THEN
      RETURN v_trade_id;
    END IF;
  END IF;

  v_total_proceeds := p_quantity * p_execution_price_inr;

  -- Lock wallet first
  PERFORM 1 FROM public.virtual_wallets WHERE user_id = p_user_id FOR UPDATE;

  SELECT id, quantity INTO v_holding_id, v_existing_qty
  FROM public.holdings
  WHERE user_id = p_user_id AND symbol = p_symbol FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No holding found for symbol %', p_symbol;
  END IF;

  IF v_existing_qty < p_quantity THEN
    RAISE EXCEPTION 'Insufficient holding: have %, need %', v_existing_qty, p_quantity;
  END IF;

  UPDATE public.virtual_wallets
  SET balance_inr = balance_inr + v_total_proceeds,
      version     = version + 1,
      updated_at  = NOW()
  WHERE user_id = p_user_id;

  IF (v_existing_qty - p_quantity) <= 0.000001 THEN
    DELETE FROM public.holdings WHERE id = v_holding_id;
    UPDATE public.stop_loss_orders
    SET status = 'cancelled'::stop_loss_status
    WHERE user_id = p_user_id AND symbol = p_symbol AND status = 'active'::stop_loss_status;
  ELSE
    UPDATE public.holdings
    SET quantity   = quantity - p_quantity,
        version    = version + 1,
        updated_at = NOW()
    WHERE id = v_holding_id;
  END IF;

  INSERT INTO public.trades (
    user_id, symbol, side, type, quantity,
    execution_price_inr, total_amount_inr,
    discipline_score_at_trade, risk_score_at_trade,
    client_order_id
  )
  VALUES (
    p_user_id, p_symbol, 'sell'::trade_side, 'market'::order_type, p_quantity,
    p_execution_price_inr, v_total_proceeds,
    v_discipline_score, v_risk_score,
    p_client_order_id
  )
  RETURNING id INTO v_trade_id;

  RETURN v_trade_id;
END;
$$;

-- Revoke all access from non-service roles
REVOKE EXECUTE ON FUNCTION public.execute_buy_order(UUID, TEXT, NUMERIC, NUMERIC, NUMERIC, UUID)
  FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.execute_sell_order(UUID, TEXT, NUMERIC, NUMERIC, UUID)
  FROM public, authenticated, anon;

-- Explicitly grant execute to service_role
GRANT EXECUTE ON FUNCTION public.execute_buy_order(UUID, TEXT, NUMERIC, NUMERIC, NUMERIC, UUID)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.execute_sell_order(UUID, TEXT, NUMERIC, NUMERIC, UUID)
  TO service_role;
