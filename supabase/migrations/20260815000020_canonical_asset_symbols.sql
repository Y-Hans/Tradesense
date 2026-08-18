-- Canonical asset symbols are the database contract for new executions.
-- Exchange pairs (for example BTCUSDT or BTCINR) remain provider metadata;
-- the wallet and holdings account in the base asset symbol.
INSERT INTO public.crypto_assets (symbol, name, is_supported_v1) VALUES
  ('BTC', 'Bitcoin', true),
  ('ETH', 'Ethereum', true),
  ('SOL', 'Solana', true),
  ('XRP', 'XRP', true),
  ('BNB', 'BNB', true)
ON CONFLICT (symbol) DO NOTHING;
