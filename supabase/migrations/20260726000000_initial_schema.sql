-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  virtual_balance_inr NUMERIC(15, 2) NOT NULL DEFAULT 100000.00,
  is_premium BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own profile" ON public.profiles
  FOR ALL USING (auth.uid() = id);

-- 2. Virtual Wallets Table
CREATE TABLE public.virtual_wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  balance_inr NUMERIC(15, 2) NOT NULL DEFAULT 100000.00,
  locked_inr NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
  initial_balance_inr NUMERIC(15, 2) NOT NULL DEFAULT 100000.00,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.virtual_wallets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own wallet" ON public.virtual_wallets
  FOR ALL USING (auth.uid() = user_id);

-- 3. Holdings Table
CREATE TABLE public.holdings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  quantity NUMERIC(28, 10) NOT NULL DEFAULT 0,
  average_entry_price_inr NUMERIC(15, 2) NOT NULL,
  current_price_inr NUMERIC(15, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_symbol UNIQUE(user_id, symbol)
);

ALTER TABLE public.holdings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own holdings" ON public.holdings
  FOR ALL USING (auth.uid() = user_id);

-- 4. Trades Table
CREATE TABLE public.trades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  side TEXT NOT NULL CHECK (side IN ('buy', 'sell')),
  type TEXT NOT NULL CHECK (type IN ('market', 'stopLoss')),
  quantity NUMERIC(28, 10) NOT NULL,
  execution_price_inr NUMERIC(15, 2) NOT NULL,
  total_amount_inr NUMERIC(15, 2) NOT NULL,
  stop_loss_price_inr NUMERIC(15, 2),
  discipline_score_at_trade INT NOT NULL DEFAULT 100,
  risk_score_at_trade INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own trades" ON public.trades
  FOR ALL USING (auth.uid() = user_id);

-- 5. Stop Loss Orders Table
CREATE TABLE public.stop_loss_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trade_id UUID REFERENCES public.trades(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  trigger_price_inr NUMERIC(15, 2) NOT NULL,
  quantity NUMERIC(28, 10) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'triggered', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.stop_loss_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own stop loss orders" ON public.stop_loss_orders
  FOR ALL USING (auth.uid() = user_id);

-- 6. Portfolio Snapshots Table
CREATE TABLE public.portfolio_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_equity_inr NUMERIC(15, 2) NOT NULL,
  unrealised_pnl_inr NUMERIC(15, 2) NOT NULL,
  realised_pnl_inr NUMERIC(15, 2) NOT NULL,
  risk_score INT NOT NULL,
  discipline_score INT NOT NULL,
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.portfolio_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own snapshots" ON public.portfolio_snapshots
  FOR ALL USING (auth.uid() = user_id);

-- 7. Risk Scores Table
CREATE TABLE public.risk_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INT NOT NULL,
  level TEXT NOT NULL,
  concentration_score NUMERIC(5, 2) NOT NULL,
  sizing_score NUMERIC(5, 2) NOT NULL,
  volatility_score NUMERIC(5, 2) NOT NULL,
  stop_loss_score NUMERIC(5, 2) NOT NULL,
  explanations JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.risk_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own risk scores" ON public.risk_scores
  FOR ALL USING (auth.uid() = user_id);

-- 8. Discipline Scores Table
CREATE TABLE public.discipline_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INT NOT NULL,
  risk_mgmt_score NUMERIC(5, 2) NOT NULL,
  position_sizing_score NUMERIC(5, 2) NOT NULL,
  stop_loss_discipline_score NUMERIC(5, 2) NOT NULL,
  concentration_score NUMERIC(5, 2) NOT NULL,
  frequency_score NUMERIC(5, 2) NOT NULL,
  breakdown_notes JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.discipline_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own discipline scores" ON public.discipline_scores
  FOR ALL USING (auth.uid() = user_id);

-- 9. AI Interactions Telemetry Table (Future Model Data Foundation)
CREATE TABLE public.ai_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trade_id UUID REFERENCES public.trades(id) ON DELETE SET NULL,
  request_payload JSONB NOT NULL,
  response_payload JSONB NOT NULL,
  ai_provider TEXT NOT NULL,
  model_id TEXT NOT NULL,
  prompt_version TEXT NOT NULL,
  latency_ms INT NOT NULL,
  success BOOLEAN NOT NULL DEFAULT TRUE,
  user_feedback_rating INT, -- 1 to 5 rating if provided
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.ai_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert own ai interactions" ON public.ai_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own ai interactions" ON public.ai_interactions
  FOR SELECT USING (auth.uid() = user_id);

-- Indexes for maximum performance
CREATE INDEX idx_holdings_user ON public.holdings(user_id);
CREATE INDEX idx_trades_user_date ON public.trades(user_id, created_at DESC);
CREATE INDEX idx_snapshots_user_date ON public.portfolio_snapshots(user_id, snapshot_date);
CREATE INDEX idx_ai_telemetry ON public.ai_interactions(user_id, created_at DESC);
