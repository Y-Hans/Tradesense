-- 20260726000018_fix_trade_analyses_rls.sql
-- Restricts public.trade_analyses to SELECT only for authenticated users.

DROP POLICY IF EXISTS "Users can access own trade analyses" ON public.trade_analyses;
DROP POLICY IF EXISTS "Users can view own trade analyses" ON public.trade_analyses;

CREATE POLICY "Users can view own trade analyses"
  ON public.trade_analyses
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
