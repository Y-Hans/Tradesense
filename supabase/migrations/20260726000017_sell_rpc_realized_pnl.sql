-- 20260726000017_sell_rpc_realized_pnl.sql
-- Updates execute_sell_order to capture holding's average_entry_price_inr and record realized_pnl.

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
  v_avg_entry        NUMERIC;
  v_realized_pnl     NUMERIC;
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

  SELECT id, quantity, average_entry_price_inr INTO v_holding_id, v_existing_qty, v_avg_entry
  FROM public.holdings
  WHERE user_id = p_user_id AND symbol = p_symbol FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No holding found for symbol %', p_symbol;
  END IF;

  IF v_existing_qty < p_quantity THEN
    RAISE EXCEPTION 'Insufficient holding: have %, need %', v_existing_qty, p_quantity;
  END IF;

  -- Realized P&L = (sell_price - avg_entry) * quantity
  v_realized_pnl := (p_execution_price_inr - v_avg_entry) * p_quantity;

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
    client_order_id, realized_pnl
  )
  VALUES (
    p_user_id, p_symbol, 'sell'::trade_side, 'market'::order_type, p_quantity,
    p_execution_price_inr, v_total_proceeds,
    v_discipline_score, v_risk_score,
    p_client_order_id, v_realized_pnl
  )
  RETURNING id INTO v_trade_id;

  RETURN v_trade_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.execute_sell_order(UUID, TEXT, NUMERIC, NUMERIC, UUID)
  FROM public, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.execute_sell_order(UUID, TEXT, NUMERIC, NUMERIC, UUID)
  TO service_role;
