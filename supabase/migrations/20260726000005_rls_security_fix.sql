-- 1. Update virtual_wallets RLS
DROP POLICY IF EXISTS "Users can access own wallet" ON public.virtual_wallets;
CREATE POLICY "Users can access own wallet" ON public.virtual_wallets FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- 2. Update holdings RLS
DROP POLICY IF EXISTS "Users can access own holdings" ON public.holdings;
CREATE POLICY "Users can access own holdings" ON public.holdings FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- 3. Update trades RLS
DROP POLICY IF EXISTS "Users can insert own trades" ON public.trades;
DROP POLICY IF EXISTS "Users can access own trades" ON public.trades;
CREATE POLICY "Users can access own trades" ON public.trades FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- 4. Update trade_analyses RLS
DROP POLICY IF EXISTS "Users can access own trade analyses" ON public.trade_analyses;
CREATE POLICY "Users can access own trade analyses" ON public.trade_analyses FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- 5. Add missing B-Tree indexes
CREATE INDEX IF NOT EXISTS idx_virtual_wallets_user_id ON public.virtual_wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_holdings_user_id ON public.holdings(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_user_id ON public.trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trade_analyses_user_id ON public.trade_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_stop_loss_orders_user_id ON public.stop_loss_orders(user_id);
