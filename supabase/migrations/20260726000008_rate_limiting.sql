CREATE TABLE IF NOT EXISTS public.ai_chat_usage (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  message_count INTEGER NOT NULL DEFAULT 0,
  reset_time TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '1 day'
);

ALTER TABLE public.ai_chat_usage ENABLE ROW LEVEL SECURITY;

-- Only service role can read/write this table freely, but let's allow users to read their own usage
CREATE POLICY "Users can read own chat usage"
  ON public.ai_chat_usage FOR SELECT
  USING (auth.uid() = user_id);

-- Edge function will use Service Role Key to bypass RLS and update this table.
