-- ============================================
-- Add is_blocked column to profiles table
-- Run this in Supabase SQL Editor
-- ============================================

-- Add is_blocked column if it doesn't exist
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;

-- Add status column if it doesn't exist (for approved/pending/blocked)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- Set default status for existing users
UPDATE profiles SET status = 'approved' WHERE status IS NULL OR status = '';

-- Verify columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('is_blocked', 'status')
ORDER BY column_name;
