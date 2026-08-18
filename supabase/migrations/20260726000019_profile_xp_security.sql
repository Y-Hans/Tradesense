-- 20260726000019_profile_xp_security.sql
-- Enforces strict protection on profiles.total_xp to prevent direct client mutations.

CREATE OR REPLACE FUNCTION public.fn_protect_profile_xp()
RETURNS TRIGGER AS $$
BEGIN
  -- If total_xp is being modified directly by an authenticated/anon client connection
  IF NEW.total_xp IS DISTINCT FROM OLD.total_xp THEN
    IF CURRENT_USER IN ('authenticated', 'anon') THEN
      RAISE EXCEPTION 'Direct modification of total_xp is strictly forbidden';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_profile_xp ON public.profiles;
CREATE TRIGGER trg_protect_profile_xp
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.fn_protect_profile_xp();

-- Refine RLS policies for profiles
DROP POLICY IF EXISTS "Users can access own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
