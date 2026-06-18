-- ============================================
-- CHECK NOTIFICATIONS TABLE CONSTRAINT
-- Run this in Supabase SQL Editor to see current notification types
-- ============================================

-- Check current constraint
SELECT conname, pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'notifications'::regclass
AND contype = 'c';

-- Check if notifications table exists
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'notifications';

-- Show current notification types in use
SELECT type, COUNT(*) as count
FROM notifications
GROUP BY type;
