-- 20260726000006_one_time_cleanup.sql
-- DEVELOPMENT REFERENCE ONLY. Original content deleted all auth.users for dev cleanup.
-- THIS MIGRATION IS A DELIBERATE NO-OP in automated replay (supabase db reset/push).
-- To perform a manual dev data wipe, run the following ONLY against a dev-only
-- instance with an explicit checkpoint backup:
--   DELETE FROM auth.users; -- WARNING: cascades to ALL user data.
-- DO NOT RUN AGAINST PRODUCTION OR ANY INSTANCE WITH REAL DATA.
SELECT 1; -- no-op
