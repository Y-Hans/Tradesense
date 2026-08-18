-- 20260726000010_xp_backend.sql

CREATE TABLE public.xp_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    reason TEXT NOT NULL,
    source_ref UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.mission_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mission_id TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    UNIQUE(user_id, mission_id)
);

CREATE TABLE public.verified_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    reference_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_xp_ledger_user_id ON public.xp_ledger(user_id);
CREATE INDEX idx_mission_progress_user_id ON public.mission_progress(user_id);
CREATE INDEX idx_verified_events_user_id ON public.verified_events(user_id);

-- RLS
ALTER TABLE public.xp_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verified_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own xp ledger"
    ON public.xp_ledger
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own mission progress"
    ON public.mission_progress
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own verified events"
    ON public.verified_events
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Trigger Function for Trade Events
CREATE OR REPLACE FUNCTION fn_process_trade_events()
RETURNS TRIGGER AS $$
DECLARE
    v_mission_completed BOOLEAN;
BEGIN
    -- 1. Insert Verified Event
    INSERT INTO public.verified_events (user_id, event_type, reference_id)
    VALUES (NEW.user_id, 'TRADE_EXECUTED', NEW.id);

    -- 2. Check "First Trade" Mission
    SELECT is_completed INTO v_mission_completed
    FROM public.mission_progress
    WHERE user_id = NEW.user_id AND mission_id = 'first_trade';

    IF NOT FOUND THEN
        -- Create record and complete
        INSERT INTO public.mission_progress (user_id, mission_id, is_completed, completed_at)
        VALUES (NEW.user_id, 'first_trade', TRUE, NOW());

        -- Award 50 XP
        INSERT INTO public.xp_ledger (user_id, amount, reason, source_ref)
        VALUES (NEW.user_id, 50, 'First Trade Mission', NEW.id);

        -- Update Profile
        UPDATE public.profiles
        SET total_xp = total_xp + 50
        WHERE id = NEW.user_id;
    END IF;

    -- Return the new trade record
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_trade_executed
AFTER INSERT ON public.trades
FOR EACH ROW
EXECUTE FUNCTION fn_process_trade_events();
