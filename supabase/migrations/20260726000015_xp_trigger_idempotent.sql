-- 20260726000015_xp_trigger_idempotent.sql
-- Adds UNIQUE constraint to verified_events and ensures idempotent trigger for trade XP.

ALTER TABLE public.verified_events
  ADD CONSTRAINT uq_verified_events_user_ref UNIQUE (user_id, reference_id);

CREATE OR REPLACE FUNCTION public.fn_process_trade_events()
RETURNS TRIGGER AS $$
DECLARE
  v_event_inserted INTEGER := 0;
  v_mission_inserted INTEGER := 0;
BEGIN
  -- 1. Idempotent event record
  INSERT INTO public.verified_events (user_id, event_type, reference_id)
  VALUES (NEW.user_id, 'TRADE_EXECUTED', NEW.id)
  ON CONFLICT (user_id, reference_id) DO NOTHING;

  GET DIAGNOSTICS v_event_inserted = ROW_COUNT;
  IF v_event_inserted = 0 THEN
    RETURN NEW; -- Duplicate event, skip processing
  END IF;

  -- 2. "First Trade" mission progress
  INSERT INTO public.mission_progress (user_id, mission_id, is_completed, completed_at)
  VALUES (NEW.user_id, 'first_trade', TRUE, NOW())
  ON CONFLICT (user_id, mission_id) DO NOTHING;

  GET DIAGNOSTICS v_mission_inserted = ROW_COUNT;

  -- 3. Award 50 XP only if this first_trade mission was newly inserted
  IF v_mission_inserted > 0 THEN
    INSERT INTO public.xp_ledger (user_id, amount, reason, source_ref)
    VALUES (NEW.user_id, 50, 'First Trade Mission', NEW.id);

    UPDATE public.profiles
    SET total_xp = total_xp + 50
    WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
