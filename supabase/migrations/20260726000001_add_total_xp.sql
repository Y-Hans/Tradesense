-- 20260726000001_add_total_xp.sql
-- Adds total_xp column to profiles table, required by subsequent XP triggers and models.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_xp INTEGER NOT NULL DEFAULT 0;
