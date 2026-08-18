CREATE OR REPLACE FUNCTION execute_buy_order(
  p_symbol TEXT,
  p_quantity NUMERIC,
  p_execution_price_inr NUMERIC,
  p_stop_loss_price_inr NUMERIC DEFAULT NULL,
  p_discipline_score INTEGER DEFAULT 0,
  p_risk_score INTEGER DEFAULT 0
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_wallet_balance NUMERIC;
  v_total_cost NUMERIC;
  v_trade_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_total_cost := p_quantity * p_execution_price_inr;

  -- Lock wallet
  SELECT balance_inr INTO v_wallet_balance
  FROM public.virtual_wallets
  WHERE user_id = v_user_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found';
  END IF;

  IF v_wallet_balance < v_total_cost THEN
    RAISE EXCEPTION 'Insufficient funds';
  END IF;

  -- Update wallet
  UPDATE public.virtual_wallets
  SET balance_inr = balance_inr - v_total_cost,
      version = version + 1,
      updated_at = NOW()
  WHERE user_id = v_user_id;

  -- Upsert Holding securely against phantom reads
  INSERT INTO public.holdings (user_id, symbol, quantity, average_entry_price_inr)
  VALUES (v_user_id, p_symbol, p_quantity, p_execution_price_inr)
  ON CONFLICT (user_id, symbol) DO UPDATE
  SET
      average_entry_price_inr = ((public.holdings.quantity * public.holdings.average_entry_price_inr) + v_total_cost) / (public.holdings.quantity + EXCLUDED.quantity),
      quantity = public.holdings.quantity + EXCLUDED.quantity,
      version = public.holdings.version + 1,
      updated_at = NOW();

  -- Insert Trade
  INSERT INTO public.trades (user_id, symbol, side, type, quantity, execution_price_inr, total_amount_inr, stop_loss_price_inr, discipline_score_at_trade, risk_score_at_trade)
  VALUES (v_user_id, p_symbol, 'buy'::trade_side, 'market'::order_type, p_quantity, p_execution_price_inr, v_total_cost, p_stop_loss_price_inr, p_discipline_score, p_risk_score)
  RETURNING id INTO v_trade_id;

  -- Insert Stop Loss if provided
  IF p_stop_loss_price_inr IS NOT NULL THEN
    INSERT INTO public.stop_loss_orders (trade_id, user_id, symbol, trigger_price_inr, quantity)
    VALUES (v_trade_id, v_user_id, p_symbol, p_stop_loss_price_inr, p_quantity);
  END IF;

  RETURN v_trade_id;
END;
$$;


CREATE OR REPLACE FUNCTION execute_sell_order(
  p_symbol TEXT,
  p_quantity NUMERIC,
  p_execution_price_inr NUMERIC,
  p_discipline_score INTEGER DEFAULT 0,
  p_risk_score INTEGER DEFAULT 0
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_total_proceeds NUMERIC;
  v_trade_id UUID;
  v_holding_id UUID;
  v_existing_qty NUMERIC;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_total_proceeds := p_quantity * p_execution_price_inr;

  -- Lock wallet first to prevent deadlocks (buy order locks wallet first)
  PERFORM 1 FROM public.virtual_wallets WHERE user_id = v_user_id FOR UPDATE;

  -- Lock Holding
  SELECT id, quantity INTO v_holding_id, v_existing_qty
  FROM public.holdings
  WHERE user_id = v_user_id AND symbol = p_symbol FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Holding not found';
  END IF;

  IF v_existing_qty < p_quantity THEN
    RAISE EXCEPTION 'Insufficient holding quantity';
  END IF;

  -- Update wallet
  UPDATE public.virtual_wallets
  SET balance_inr = balance_inr + v_total_proceeds,
      version = version + 1,
      updated_at = NOW()
  WHERE user_id = v_user_id;

  -- Update Holding
  IF (v_existing_qty - p_quantity) <= 0.000001 THEN
    DELETE FROM public.holdings WHERE id = v_holding_id;
    -- Also cancel active stop losses
    UPDATE public.stop_loss_orders SET status = 'cancelled'::stop_loss_status WHERE user_id = v_user_id AND symbol = p_symbol AND status = 'active'::stop_loss_status;
  ELSE
    UPDATE public.holdings
    SET quantity = quantity - p_quantity,
        version = version + 1,
        updated_at = NOW()
    WHERE id = v_holding_id;
  END IF;

  -- Insert Trade
  INSERT INTO public.trades (user_id, symbol, side, type, quantity, execution_price_inr, total_amount_inr, discipline_score_at_trade, risk_score_at_trade)
  VALUES (v_user_id, p_symbol, 'sell'::trade_side, 'market'::order_type, p_quantity, p_execution_price_inr, v_total_proceeds, p_discipline_score, p_risk_score)
  RETURNING id INTO v_trade_id;

  RETURN v_trade_id;
END;
$$;
