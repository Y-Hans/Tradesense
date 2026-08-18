-- 20260726000014_atomic_rate_limit.sql
-- Provides a concurrency-safe, atomic AI rate-limit increment function.
-- Uses pg_advisory_xact_lock to serialize concurrent requests per user.

CREATE OR REPLACE FUNCTION public.fn_increment_ai_usage(p_user_id UUID)
RETURNS TABLE(allowed BOOLEAN, count_after INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_count   INTEGER;
  v_allowed BOOLEAN;
BEGIN
  -- Advisory xact lock serializes concurrent requests for the same user.
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  INSERT INTO public.ai_chat_usage (user_id, message_count, reset_time)
  VALUES (p_user_id, 1, NOW() + INTERVAL '1 day')
  ON CONFLICT (user_id) DO UPDATE SET
    message_count = CASE
      WHEN ai_chat_usage.reset_time < NOW() THEN 1
      ELSE ai_chat_usage.message_count + 1
    END,
    reset_time = CASE
      WHEN ai_chat_usage.reset_time < NOW() THEN NOW() + INTERVAL '1 day'
      ELSE ai_chat_usage.reset_time
    END
  RETURNING message_count INTO v_count;

  v_allowed := v_count <= 20;

  -- If quota was exceeded, roll back the increment count
  IF NOT v_allowed THEN
    UPDATE public.ai_chat_usage
    SET message_count = message_count - 1
    WHERE user_id = p_user_id;
    v_count := v_count - 1;
  END IF;

  RETURN QUERY SELECT v_allowed, v_count;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.fn_increment_ai_usage(UUID) FROM public, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.fn_increment_ai_usage(UUID) TO service_role;
