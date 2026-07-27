# Database Schema & Security (Supabase PostgreSQL)

## PostgreSQL Tables Overview
1. `profiles`: Private user profiles with ₹100,000 balance state and premium flag.
2. `virtual_wallets`: Tracks available and locked virtual INR balance.
3. `holdings`: Active crypto positions per user (`user_id`, `symbol`).
4. `trades`: Immutable order history with execution price, quantity, stop-loss, and discipline score at time of trade.
5. `stop_loss_orders`: Pending stop-loss triggers.
6. `portfolio_snapshots`: Daily equity snapshots for P&L charts.
7. `risk_scores`: Historical risk score breakdowns.
8. `discipline_scores`: Historical discipline score breakdowns.
9. `ai_interactions`: Structured telemetry recording prompt inputs, OpenRouter responses, latencies, model ID, and user feedback ratings for future model training datasets.

## Row Level Security (RLS)
All private tables enforce strict RLS:
```sql
CREATE POLICY "Users can access own data" ON public.<table_name>
  FOR ALL USING (auth.uid() = user_id);
```
Never bypass RLS on client devices.
